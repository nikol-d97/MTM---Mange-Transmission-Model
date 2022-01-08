extensions [gis]

breed [foxes fox]

globals [
  landcover-map
  resistance-map
  index-map
  dispersal-index-map
  step ;step length found from weibull distribution
  mean-move-length ;mean movement length
  corr ;correlation in movement direction
  mean-turn-angle ;mean angle moved for CRW
  XC YC ;target patch in upper right forest cluster
  XC2 YC2 ;target patch in lower left forest cluster
  Re-SEI ;Re calculation of SEI model
  attack-rate ;attack rate calculation of SEI model
]

patches-own [
  landcover ;landcover type: 1 - Forest patch, 2 - Commercial, 3 - High density residential, 4 - Industrial, 5 - Institutional, 6 - Forest edge,
            ;7 - Landscaped green area, 8 - Linear feature, 9 - Medium density residential, 10 - Natural
  resistance ;resistance to movement according to landcover type
  index ;1 - left forest patch, 2 - right forest patch
  dispersal-index ;1 - left forest patch edge, 2 - right forest patch edge
]

foxes-own [
  movement-index ;foxes disperse according to current patch they are in
  susceptible? ;is fox susceptible?
  latent? ;is fox in latent stage?
  infected? ;is fox in disease stage?
  latent-period-time ;counter for latent period after which an individual becomes infectious
  latent-period-length ;derived from exponential distribution
  infectious-period-time ;counter for infectious period after which an individual goes back to the susceptible period
  infectious-period-length ;dervied from exponential distribution
  infection-counter ;counter for each turtle and how many turtles it infects
  place-infected ;landcover type where infection occurs
  overall-infection ;number of transmission events
  forest-infected ;counter for turtles infected in forest
  commercial-infected ;counter for turtles infected in commercial area
  HDR-infected ;counter for turtles infected in HDR
  industrial-infected ;counter for turtles infected in industrial area
  institutional-infected ;counter for turtles infected in institutional area
  forest-edge-infected ;counter for turtles infected in forest edge
  landscaped-green-area-infected ;counter for turtles infected in landscaped green area
  road-infected ;counter for turtles infected in road
  MDR-infected ;counter for turtles infected in MDR
  natural-infected ;counter for turtles infected in natural area

]

to setup
  ca
  set mean-move-length 1
  set corr 0.9
  set mean-turn-angle 180
  set XC 70
  set YC -61
  set XC2 6
  set YC2 -8

  set landcover-map gis:load-dataset "sm_land.asc"
  set resistance-map gis:load-dataset "sm_resist.asc"
  set index-map gis:load-dataset "sm_index.asc"
  set dispersal-index-map gis:load-dataset "sm_disper.asc"

  gis:set-world-envelope gis:envelope-of landcover-map

  gis:apply-raster landcover-map landcover
  gis:apply-raster resistance-map resistance
  gis:apply-raster index-map index
  gis:apply-raster dispersal-index-map dispersal-index

  ask patches ;setting colors of patches according to landcover type
  [
   (ifelse
    landcover = 1 [
     set pcolor green ;forest
     set resistance resistance + random-float 0.8
     ]
     landcover = 2 [
     set pcolor gray  ;Commercial
     set resistance resistance + random-float 0.8
     ]
     landcover = 3 [
        set pcolor red ;HDR: High density residential
        set resistance resistance + random-float 0.8
     ]
     landcover = 4 [
        set pcolor gray ;Industrial
        set resistance resistance + random-float 0.8
     ]
     landcover = 5 [
      set pcolor yellow ;Institutional
      set resistance resistance + random-float 0.8
     ]
     landcover = 6 [
      set pcolor green - 2 ;forest edge
      set resistance resistance + random-float 0.8
    ]
     landcover = 7 [
          set pcolor yellow ;Landscaped green area
        set resistance resistance + random-float 0.8
     ]
     landcover = 8 [
         set pcolor gray ;Road
        set resistance resistance + random-float 0.8
     ]
     landcover = 9 [
        set pcolor orange ;MDR: Medium density residential
        set resistance resistance + random-float 0.8
     ]
     landcover = 10 [
        set pcolor 59 ;Natural
        set resistance resistance + random-float 0.8
     ])
  ]

    ask n-of num-foxes-top-patch patches with [pcolor = green and pycor > -35] [
    sprout-foxes 1 ]
   ask n-of num-foxes-bottom-patch patches with [pcolor = green and pycor < -35] [
    sprout-foxes 1 ]
  ask foxes [
    set shape "wolf"
    set color orange - 2
    set size 4
    set place-infected -1
    set infection-counter 0
    set overall-infection 0
    set forest-infected 0
    set commercial-infected 0
    set HDR-infected 0
    set industrial-infected 0
    set institutional-infected 0
    set forest-edge-infected 0
    set landscaped-green-area-infected 0
    set road-infected 0
    set MDR-infected 0
    set natural-infected 0


    become-susceptible
    if [index] of patch-here = 1 [
      set movement-index 1 ]
    if [index] of patch-here = 2 [
      set movement-index 2]
  ]

 ask n-of initial-num-infected-foxes foxes [become-infected
   set place-infected [landcover] of patch-here
   set infectious-period-length random-exponential average-infectious-period * ticks-per-day
   set infectious-period-time 0 ]

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; go procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  move-within-forest
  disperse-out-of-forest
  move-off-world-boundary
  clear-count
  spread
  if ticks = 150000 [stop]
  calculate-Re
  calculate-attack-rate
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; if fox in forest: move-within-forest procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-within-forest
  ask foxes [
    if  [landcover] of patch-here = 1 and [dispersal-index] of patch-here = 0 [
set heading heading + one-of [-1 1] * 10000 * angle corr mean-turn-angle
set step weibull-dist 2 10 mean-move-length
     fd 50 * step
  ]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CRW angle reporter ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report angle [ p mean-angle ]
  let movement-angle ( ( 1 - p ^ 2) / ( 2 * 180 * ( 1 + (p ^ 2 ) - 2 * p * cos ( ( angle-range 0 360 ) - mean-angle ) ) ) )
  report movement-angle
end


to-report angle-range [ _min _max ]
  report _min + random-float ( _max - _min )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CRW step reporter ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report weibull-dist [ _shape _scale _mean-step-length ]
  let mean-step-length ( ( _shape / _scale ) * ( ( _mean-step-length / _scale ) ^ ( _shape - 1 ) ) * exp ( ( _mean-step-length / _scale ) ^ ( _shape ) ) )
  report mean-step-length
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; If fox in forest edge: disperse-out-of-forest procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to disperse-out-of-forest
  let dis-prob random-float 1.0

  ask foxes with [movement-index = 1 and susceptible?] [
    if [dispersal-index] of patch-here = 1 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-susceptible [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 1 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC YC
    let candidates (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
      ifelse least-cost-path? [
        move-to min-one-of candidates [resistance]]
      [move-to one-of candidates]]
    if [index] of patch-here = 2 [
      set movement-index 2 ]
    ]

  ask foxes with [movement-index = 2 and susceptible?] [
    if [dispersal-index] of patch-here = 2 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-susceptible [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 2 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC2 YC2
    let candidates2 (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
       ifelse least-cost-path? [
        move-to min-one-of candidates2 [resistance]]
      [move-to one-of candidates2]]
     if [index] of patch-here = 1 [
      set movement-index 1 ]
  ]

   ask foxes with [movement-index = 1 and latent?] [
    if [dispersal-index] of patch-here = 1 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-susceptible [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 1 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC YC
    let candidates (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
       ifelse least-cost-path? [
        move-to min-one-of candidates [resistance]]
      [move-to one-of candidates]]
    if [index] of patch-here = 2 [
      set movement-index 2 ]
    ]

  ask foxes with [movement-index = 2 and latent?] [
    if [dispersal-index] of patch-here = 2  and [landcover] of patch-here = 6[
      ifelse dis-prob <= dispersal-probability-susceptible [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 2 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC2 YC2
    let candidates2 (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
      ifelse least-cost-path? [
        move-to min-one-of candidates2 [resistance]]
      [move-to one-of candidates2]]
     if [index] of patch-here = 1 [
      set movement-index 1 ]
  ]

    ask foxes with [movement-index = 1 and infected?] [
    if [dispersal-index] of patch-here = 1 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-infected [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 1 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC YC
    let candidates (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
       ifelse least-cost-path? [
        move-to min-one-of candidates [resistance]]
      [move-to one-of candidates]]
    if [index] of patch-here = 2 [
      set movement-index 2 ]
    ]

  ask foxes with [movement-index = 2 and infected?] [
    if [dispersal-index] of patch-here = 2 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-infected [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 2 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC2 YC2
    let candidates2 (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
      ifelse least-cost-path? [
        move-to min-one-of candidates2 [resistance]]
      [move-to one-of candidates2]]
     if [index] of patch-here = 1 [
      set movement-index 1 ]
  ]


end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Move away from world boundaries ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-off-world-boundary
  ask foxes [
  if abs pxcor = max-pxcor
    [ set heading (- heading) ]
  ;; bounce off top and bottom walls
  if abs pycor = max-pycor
    [ set heading (180 - heading) ]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Disease spread procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to spread
   let prob random-float 1.0
  ask foxes  [
  ifelse infected? [] [
  if any? other foxes in-radius 1 with [ infected? ] and prob <= transmission-probability
  [ become-latent
    set latent-period-length random-exponential average-latent-period * ticks-per-day
    set latent-period-time 0
    set place-infected [landcover] of patch-here
    if place-infected = 1 [
          set forest-infected forest-infected + 1]
    if place-infected = 2 [
          set commercial-infected commercial-infected + 1]
    if place-infected = 3 [
          set HDR-infected HDR-infected + 1]
    if place-infected = 4 [
          set industrial-infected industrial-infected + 1]
    if place-infected = 5 [
          set institutional-infected institutional-infected + 1]
    if place-infected = 6 [
          set forest-edge-infected forest-edge-infected + 1]
    if place-infected = 7 [
          set landscaped-green-area-infected landscaped-green-area-infected + 1]
    if place-infected = 8 [
          set road-infected road-infected + 1]
    if place-infected = 9 [
          set MDR-infected MDR-infected + 1]
    if place-infected = 10 [
          set natural-infected natural-infected + 1]
    set infection-counter infection-counter + 1
    set overall-infection overall-infection + 1
      ]
    ]
  ]

  ask foxes [
    if latent-period-time > latent-period-length ;if latent period counter is greater than exponentially derived latent period with avg of 30 days, become infected
    [
     become-infected
     set infectious-period-length random-exponential average-infectious-period * ticks-per-day
     set infectious-period-time 0
     set latent-period-time 0
          ]
  ]

  ask foxes [
       if infectious-period-time > infectious-period-length ;infectious-period is a slider variable set to 100
    [
      become-susceptible
      set infectious-period-time 0
    ]
  ]

 ask foxes [
   if latent?
   	[
      set latent-period-time latent-period-time + 1 ]
if infected?
     [
            set infectious-period-time infectious-period-time + 1]
  ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; clears count for infection counter;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to clear-count
  ask foxes with [susceptible?] [
    set infection-counter 0 ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; disease states ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to become-susceptible
  set infected? false
  set latent? false
  set susceptible? true
  set color orange - 2
end

to become-latent
  set latent? true
  set infected? false
  set susceptible? false
  set color gray - 2
end

to become-infected
  set latent? false
  set infected? true
  set susceptible? false
  set color blue
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Re Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-Re
  set re-SEI mean [infection-counter] of foxes
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; attack rate Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-attack-rate
  set attack-rate count foxes with [infected?] * 100 / (num-foxes-top-patch + num-foxes-bottom-patch)
end
@#$#@#$#@
GRAPHICS-WINDOW
346
10
1002
511
-1
-1
6.0
1
10
1
1
1
0
0
0
1
0
107
-81
0
0
0
1
ticks
30.0

BUTTON
12
24
75
57
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
108
189
141
num-foxes-top-patch
num-foxes-top-patch
0
50
8.0
1
1
NIL
HORIZONTAL

SLIDER
13
153
194
186
num-foxes-bottom-patch
num-foxes-bottom-patch
0
50
8.0
1
1
NIL
HORIZONTAL

SLIDER
9
198
199
231
initial-num-infected-foxes
initial-num-infected-foxes
0
15
1.0
1
1
NIL
HORIZONTAL

BUTTON
92
23
155
56
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
238
191
271
transmission-probability
transmission-probability
0
1
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
13
277
185
310
average-latent-period
average-latent-period
0
35
30.0
1
1
NIL
HORIZONTAL

SLIDER
7
316
200
349
average-infectious-period
average-infectious-period
0
120
120.0
1
1
NIL
HORIZONTAL

SLIDER
18
69
193
102
ticks-per-day
ticks-per-day
0
100
100.0
1
1
ticks/day
HORIZONTAL

SLIDER
3
355
229
388
dispersal-probability-susceptible
dispersal-probability-susceptible
0.25
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
8
396
218
429
dispersal-probability-infected
dispersal-probability-infected
0.25
1
0.75
0.05
1
NIL
HORIZONTAL

MONITOR
1109
201
1166
246
NIL
Re-SEI
17
1
11

MONITOR
1177
201
1234
246
days
ticks / ticks-per-day
17
1
11

SWITCH
173
22
319
55
least-cost-path?
least-cost-path?
0
1
-1000

PLOT
1029
35
1229
185
Disease State vs. Time
Days
Number of foxes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"S" 1.0 0 -955883 true "" "plotxy (ticks / ticks-per-day) count foxes with [susceptible?] "
"E" 1.0 0 -7500403 true "" "plotxy (ticks / ticks-per-day) count foxes with [latent?]"
"I" 1.0 0 -13345367 true "" "plotxy (ticks / ticks-per-day) count foxes with [infected?] "

MONITOR
1024
200
1099
245
NIL
attack-rate
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [go]</go>
    <timeLimit steps="150000"/>
    <exitCondition>not any? foxes with [infected?]</exitCondition>
    <metric>R0-SEI</metric>
    <metric>attack-rate</metric>
    <metric>sum [overall-infection] of turtles</metric>
    <metric>sum [forest-infected] of turtles</metric>
    <metric>sum [HDR-infected] of turtles</metric>
    <metric>sum [MDR-infected] of turtles</metric>
    <metric>sum [natural-infected] of turtles</metric>
    <metric>sum [road-infected] of turtles</metric>
    <metric>sum [forest-edge-infected] of turtles</metric>
    <metric>sum [industrial-infected] of turtles</metric>
    <metric>sum [institutional-infected] of turtles</metric>
    <metric>sum [commercial-infected] of turtles</metric>
    <metric>sum [landscaped-green-area-infected] of turtles</metric>
    <enumeratedValueSet variable="dispersal-probability-susceptible">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="least-cost-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-latent-period">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-probability">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-probability-infected">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-infectious-period">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticks-per-day">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-foxes-bottom-patch">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-num-infected-foxes">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-foxes-top-patch">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
