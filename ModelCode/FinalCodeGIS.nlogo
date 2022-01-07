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
  R0-SEI ;R0 calculation of SEI model
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
  movement-index ;foxes move out of a forest patch according to current patch they are in
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

  ask patches ;setting colors of patches according to landcover type - 
              ; added a random float to each resistance value to allow for spatial heterogeneity in movement within each landcover type 
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

; set the location of the foxes at the start of the simulation 
; set up fox-owned parameter values 
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

; set initial number of infected foxes 
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
  calculate-R0
  calculate-attack-rate
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; if fox in forest: move-within-forest procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; foxes perform a correlated random walk within the forest 
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
  let movement-angle ( ( 1 - p^2) / ( 2 * 180 * ( 1 + (p^2 ) - 2 * p * cos ( ( angle-range 0 360 ) - mean-angle ) ) ) )
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

; movement of susceptible foxes from left patch to right patch
  ask foxes with [movement-index = 1 and susceptible?] [
    if [dispersal-index] of patch-here = 1 and [landcover] of patch-here = 6 [
      ifelse dis-prob <= dispersal-probability-susceptible [ fd 1]
      [bk 1]]
    if [dispersal-index] of patch-here != 1 and [landcover] of patch-here != 1 [ ;; if the fox is not on a patch with landcover = 1
      facexy XC YC
    let candidates (patch-set patch-right-and-ahead 30 1
                              patch-left-and-ahead 30 1
                              patch-ahead 1)
      ifelse least-cost-path? [ ;if least-cost path switch is on - move according to resistance values 
        move-to min-one-of candidates [resistance]]
      [move-to one-of candidates]]
    if [index] of patch-here = 2 [
      set movement-index 2 ]
    ]

; movement of susceptible foxes from right patch to left patch 
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

; movement of latent foxes from left patch to right patch (same probability of dispersing as susceptible individuals)
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


; movement of latent foxes from right patch to left patch (same probability of dispersing as susceptible individuals)
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

; movement of infected foxes from left patch to right patch 
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

; movement of infected foxes from right patch to left patch 
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

;fixes boundary issues if foxes hit one of the world boundaries and become stuck 
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
    set place-infected [landcover] of patch-here ;records the number of effective contact events in each of the landcover types 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; R0 Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-R0
  set r0-SEI mean [infection-counter] of foxes
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; attack rate Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-attack-rate
  set attack-rate count foxes with [infected?] * 100 / (num-foxes-top-patch + num-foxes-bottom-patch)
end