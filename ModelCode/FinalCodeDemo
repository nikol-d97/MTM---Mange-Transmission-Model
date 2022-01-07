breed [foxes fox]

globals [
step ;step size found from weibull distribution
mean-move-length ;mean movement length
corr ;correlation in movement direction
mean-turn-angle ;mean angle moved for CRW
XC YC ;target patch in upper right forest cluster
XC2 YC2 ;target patch in lower left forest cluster
Re-SEI ;R0 calculation of SEI model
attack-rate ;attack rate calculation of SEI model
]


patches-own [
  resistance ;resistance to movement according to landcover type
  landcover ;landcover type: HDR, MDR, Road, Forest, Open Field
  index ;forest cluster: 1 - left ravine 2 - upper right forest cluster
  dispersal-index ;forest cluster edge: 1 - left ravine edge 2 - upper right forest edge
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
  overall-infection ;number of transmission events
  overall-contact ;contact between suseptible and infected
  place-infected ;landcover type where infection occurs
  forest-infected ;counter for turtles infected in forest
  HDR-infected ;counter for turtles infected in HDR
  MDR-infected ;counter for turtles infected in MDR
  open-area-infected ;counter for turtles infected in open area
  road-infected ;counter for turtles infected in road
  forest-edge-infected ;counter for turtles infected in forest edge
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup procedure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ca
  set mean-move-length 1
  set corr 0.9
  set mean-turn-angle 180
  set XC 95
  set YC -5
  set XC2 10
  set YC2 -40

  file-open "landscape-border-new.txt" ;file reading procedure with xy coordinates, landcover types, and resistance values
  while [not file-at-end?]
  [
    let next-X file-read
    let next-Y file-read
    let next-landcover file-read
    let next-resistance file-read
    let next-index file-read
    let next-dispersal-index file-read
    ask patch next-X next-Y [set landcover next-landcover]
    ask patch next-X next-Y [set resistance next-resistance]
    ask patch next-X next-Y [set index next-index]
    ask patch next-X next-Y [set dispersal-index next-dispersal-index]
  ]
  file-close

  ask patches ;setting colors of patches according to landcover type
  [
   (ifelse
    landcover = 1 [
     set pcolor green ;forest
     ]
     landcover = 2 [
     set pcolor red ;HDR: High Density Residential
      ]
      landcover = 3 [
        set pcolor orange ;MDR: Medium Density Residential
      ]
      landcover = 4 [
        set pcolor yellow ;open area
      ]
      landcover = 5 [
      set pcolor gray ;road
    ]
    landcover = 6 [
      set pcolor green - 2 ;forest edge
    ])

   set resistance resistance + random-float 0.8 ;added noise to resistance
  ]


  ask n-of num-foxes-left-patch patches with [pcolor = green and pxcor < 40] [
    sprout-foxes 1 ]
   ask n-of num-foxes-right-patch patches with [pcolor = green and pxcor > 40] [
    sprout-foxes 1 ]
  ask foxes [
    set shape "wolf"
    set color orange - 2
    set size 4
    set place-infected -1
    set infection-counter 0
    set overall-infection 0
    set overall-contact 0
    set forest-infected 0
    set HDR-infected 0
    set MDR-infected 0
    set open-area-infected 0
    set road-infected 0
    set forest-edge-infected 0
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
  calculate-R0
  calculate-attack-rate
  tick
 ; write-file
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
  ;; bounce off left and right walls
  if pxcor = 23 and pycor = -73 [
      set heading ( 180 - heading)]
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
  if any? other foxes in-radius 1 with [ infected? ] [
        set overall-contact overall-contact + 1
    ]
  ]
  ]
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
          set HDR-infected HDR-infected + 1]
    if place-infected = 3 [
          set MDR-infected MDR-infected + 1]
    if place-infected = 4 [
          set open-area-infected open-area-infected + 1]
    if place-infected = 5 [
          set road-infected road-infected + 1]
    if place-infected = 6 [
          set forest-edge-infected forest-edge-infected + 1]
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
  set color gray
end

to become-infected
  set latent? false
  set infected? true
  set susceptible? false
  set color blue
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; R0 Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-Re
  set re-SEI mean [infection-counter] of foxes
;  let susceptible-t
 ;   (num-foxes-left-patch + num-foxes-right-patch) -
  ;  count turtles with [ infected? ] -
   ; count turtles with [ latent? ]
   ;if (num-foxes-left-patch + num-foxes-right-patch) - susceptible-t != 0 and susceptible-t != 0 [
    ;set r0-SEI ln(susceptible-t * transmission-probability) / ((1 / average-infectious-period) * (num-foxes-left-patch + num-foxes-right-patch)) ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; attack rate Calculation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-attack-rate
  set attack-rate count foxes with [infected?] * 100 / (num-foxes-left-patch + num-foxes-right-patch)
end

