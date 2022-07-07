extensions [table array nw rnd]

globals [colour-list base-colour-list num-type1s num-type2s num-type3s trace?
         zero-cf incr-cf decr-cf sing-cf dble-cf scep-cf fixr-cf red-cf blue-cf yell-cf
         anti-red-cf anti-blue-cf anti-yell-cf blue-red-cf red-blue-cf blue-yell-cf yell-blue-cf blue-or-yell-cf
         nk0-cf nk1-cf nk2-cf nk3-cf nk4-cf nk5-cf nk6-cf
         opinion-fn drop-rate prob-drop-link
         poss-bs num-arcs any-change? no-change-for end-tick max-num
         av-hamming sd-hamming max-hamming av-linked-hamming sd-linked-hamming max-linked-hamming
         consensus prop-consensus possible-states av-opinion  sd-opinion  av-opinion-type1 sd-opinion-type1
         av-opinion-type2 sd-opinion-type2 av-opinion-type3 sd-opinion-type3
         num-0-beliefs num-1-beliefs num-2-beliefs num-3-beliefs num-4-beliefs num-5-beliefs
         num-6-beliefs num-7-beliefs num-8-beliefs num-9-beliefs num-10-beliefs num-11-beliefs
         num-12-beliefs num-no-beliefs num-0+1-beliefs
         pi-a pi-l pi-t het-prop prop-l-consensus num-components
         num-bels-ch num-links-ch num-bels-ch-disp num-links-ch-disp cumm-bel-ch cumm-link-ch
         av-num-links glob-clustering
         consensus-type1 het-prop-type1 prop-l-consensus-type1 insularity-type1
         consensus-type2 het-prop-type2 prop-l-consensus-type2 insularity-type2
         consensus-type3 het-prop-type3 prop-l-consensus-type3 insularity-type3
         secs-per-tick filename]

breed [type1s type1]
breed [type2s type2]
breed [type3s type3]

turtles-own [
    beliefs ;; beliefs are a list of 0/1
    belief-num ;; a count of number of beliefs
    coherence ;; coherence is a float recoding current coherency level
    cfn ;; cfn is the table inpl
    cfname ;; the name of the cfn
    scaling-fn ;; the scaling function on the coherence value for the type
    changed? ;; records if its beliefs have changed for auto-stop mechanism
    rejected-from ;; records if a belief has not accepted
  ]

links-own [
    rejected? ;; records if a belief was rejected along this link
  ]

to setup
  clear-all
  ifelse (strip-spaces title) = "" [set filename "Social Coherence Model"] [set filename strip-spaces title]
  set filename (word filename "-" (substring date-and-time 16 length date-and-time) "-" behaviorspace-run-number)
  set num-type1s round (num-agents * prop-of-type1)
  set num-type2s round (num-agents * prop-of-type2)
  set num-type3s num-agents - num-type1s - num-type2s
  if num-type3s < 0 [error "Impossible set of proportions of types!"]
  set num-arcs round num-agents * arcs-per-node
  set max-num 2 ^ num-beliefs - 1
  ifelse num-beliefs > 3 [
    set base-colour-list sentence [yellow blue red] remove-list [black yellow blue red] base-colors
    set colour-list fput grey n-colours (2 ^ (num-beliefs + 1))
  ] [
    set colour-list [grey yellow blue green red orange magenta brown]
    set base-colour-list [yellow blue red]
  ]
  set drop-rate copy-rate * drop-rate-prop-of-copy
  set prob-drop-link init-prob-drop-link
  make-cfs
  set opinion-fn fn-from Opinion-Fn-Name

  let type-list shuffle (sentence n-values num-type1s [1] n-values num-type2s [2] n-values num-type3s [3])

  foreach type-list [? ->
    if ? = 1 [
      create-type1s 1 [
        set beliefs n-values num-beliefs [one-with-prob init-prob-belief]
        set cfname Coherence-Fn-Type1
        set scaling-fn Scaling-Fn-Type1
        set shape "circle" set size 0.9
      ]
     ]
    if ? = 2 [
      create-type2s 1 [
        set beliefs n-values num-beliefs [one-with-prob init-prob-belief]
        set cfname Coherence-Fn-Type2
        set scaling-fn Scaling-Fn-Type2
        set shape "star" set size 1.5
      ]
    ]
    if ? = 3 [
      create-type3s 1 [
        set beliefs n-values num-beliefs [one-with-prob init-prob-belief]
        set cfname Coherence-Fn-Type3
        set scaling-fn Scaling-Fn-Type3
        set shape "triangle 2" set size 1.7
      ]
    ]
  ]
  ask turtles [initialise-cf]
  ask turtles [init-appearence]

  make-network
  arrange-turtles

  set cumm-bel-ch 0
  set cumm-link-ch 0
  calc-stats
  reset-ticks
  set secs-per-tick 0
end

to make-network
  ;;  "random" "regular" "star" "planar" "small world"
  let oth nobody
  if initial-topology = "random" [
      while [count links < num-arcs] [
        ask one-of turtles [
          ifelse prob init-sep-prob [
            set oth one-of other turtles with [breed = [breed] of myself]
          ] [
            set oth one-of other turtles
          ]
          if not linked-from? oth
            [make-link oth]
        ]
      ]
    stop
  ]
 if initial-topology = "regular" [
   let base 0
   foreach sort turtles [? ->
     ask ? [
       foreach seq 1 arcs-per-node 1 [
         make-link turtle ((who + ?) mod num-agents)
       ]
     ]
   ]
   stop
  ]
 if initial-topology = "planar" [
   foreach sort turtles [? ->
     ask ? [
       repeat arcs-per-node [
       make-link min-one-of
         (other turtles with [not linked-from? myself])
         [distance myself]
       ]
     ]
   ]
   stop
  ]
 if initial-topology = "star" [
   let centre-turtles turtles with [who < arcs-per-node]
   let other-turtles turtles with [who >= arcs-per-node]
   ask other-turtles [
     ask centre-turtles [make-link myself]
   ]
   stop
  ]
 if initial-topology = "small world" [
   let base 0
   foreach sort turtles [? ->
     ask ? [
       foreach seq 1 arcs-per-node 1 [
         make-link turtle ((who + ?) mod num-agents)
       ]
     ]
   ]
   ask links [
     if prob 0.1 [randomly-rewire-dest end1 end2]
   ]
   stop
  ]
 if initial-topology = "preferential attachment" [
   while [count links < num-arcs] [
     ask one-of turtles [
       make-link random-member (sentence one-of other turtles [end2] of links)
     ]
   ]
   stop
 ]
 error (word initial-topology " not yet implemented!!!")
end

to make-link [oth]
  if self = oth [error (word self " can't link to " oth)]
  ifelse bi-dir-arcs? [
    ifelse not link-neighbor? oth [
      create-link-with oth [init-link]
    ] [
      error (word oth " already linked with " self "!")
    ]
  ] [
    ifelse not in-link-neighbor? oth [
      create-link-from oth [init-link]
    ] [
      error (word oth " already linked to " self "!")
    ]
  ]
end

to init-link
  set color white
  set rejected? false
  show-link
end

to randomly-rewire-dest [stn enn]
  let cand-nodes no-turtles
  ifelse bi-dir-arcs?
    [
      ask stn [
        ask link-with enn [die]
        set cand-nodes other turtles with [not link-neighbor? myself]
        if any? cand-nodes [
          create-link-with one-of cand-nodes [set color white show-link]
        ]
      ]
    ]
    [
      ask stn [
        ask out-link-to enn [die]
        set cand-nodes other turtles with [not in-link-neighbor? myself]
        if any? cand-nodes [
          create-link-to one-of cand-nodes [set color white show-link]
        ]
      ]
    ]
end

to-report linked-from? [oth]
  ifelse bi-dir-arcs?
    [report link-neighbor? oth]
    [report in-link-neighbor? oth]
end

to-report linked-to? [oth]
  ifelse bi-dir-arcs?
    [report link-neighbor? oth]
    [report out-link-neighbor? oth]
end

to-report my-neighbors
  ifelse bi-dir-arcs?
    [report link-neighbors]
    [report in-link-neighbors]
end

to-report link-from [ag]
  if ag = nobody [report nobody]
  ifelse bi-dir-arcs?
    [report link-with ag]
    [report in-link-from ag]
end

to init-appearence
  setxy random-float max-pxcor random-float max-pycor
  show-turtle
  update-appearence
end

to update-appearence
  set any-change? true
  set coherence table:get cfn beliefs
  set belief-num num-of beliefs
  adjust-shade
end

to spread
  repeat 10000 / num-agents [layout-spring turtles links 0.05 2 0.25]
end

to spread-lots
  repeat 10 [spread]
end

to adjust-shade
;;  set color base-col - 3 + round (8 * (position beliefs poss-bs) / length poss-bs)
  set color item num-of beliefs colour-list
end

to arrange-turtles
;;  "random" "regular" "star" "planar" "small world"
  if initial-topology = "random"
     [repeat 100000 / num-agents [layout-spring turtles links 0.02 1 0.25]]
  if initial-topology = "regular"
     [layout-circle sort turtles 14]
  if initial-topology = "small world"
     [layout-circle sort turtles 14]
  if initial-topology = "star" [
    let centre-turtles turtles with [who < arcs-per-node]
    ifelse count centre-turtles = 1
       [layout-circle sort centre-turtles 0]
       [layout-circle sort centre-turtles 2]
     layout-circle sort turtles with [who >= arcs-per-node] 14
  ]
  if initial-topology = "preferential attachment"
   [repeat 100000 / num-agents [layout-spring turtles links 0.02 4 1]]
end

to-report one-with-prob [prb]
  ifelse prob prb [report 1] [report 0]
end

to initialise-cf
  set cfn fn-from cfname
end

to-report fn-from [str]
;;  "zero" "incr" "decr" "scep" "sing" "dble" "indr" "fixr"
  set possible-states poss-of-len num-beliefs
  let tfn table:make
  if str  = "zero" [report zero-cf]
  if str  = "incr" [report incr-cf]
  if str  = "decr" [report decr-cf]
  if str  = "scep" [report scep-cf]
  if str  = "sing" [report sing-cf]
  if str  = "dble" [report dble-cf]
  if str  = "fixr" [report fixr-cf]
  if str  = "zero" [report zero-cf]
  if str  = "indr" [
    foreach poss-bs [? ->
      table:put tfn ? rand-val
    ]
    report tfn
  ]
  if str  = "yell" [report yell-cf]
  if str  = "anti-yell" [report anti-yell-cf]
  if str  = "blue" [
    ifelse num-beliefs > 1
      [report blue-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "anti-blue" [
    ifelse num-beliefs > 1
      [report anti-blue-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "blue-yell" [
    ifelse num-beliefs > 1
      [report blue-yell-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "yell-blue" [
    ifelse num-beliefs > 1
      [report yell-blue-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "blue-or-yell" [
    ifelse num-beliefs > 1
      [report blue-or-yell-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "red" [
    ifelse num-beliefs > 2
      [report red-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "anti-red" [
    ifelse num-beliefs > 2
      [report anti-red-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "blue-red" [
    ifelse num-beliefs > 2
      [report blue-red-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "red-blue" [
    ifelse num-beliefs > 2
      [report red-blue-cf]
      [error (word str  " can't be used with " num-beliefs " beliefs!!!")]
  ]
  if str  = "nk0" [report nk0-cf]
  if str  = "nk1" [report nk1-cf]
  if str  = "nk2" [report nk2-cf]
  if str  = "nk3" [report nk3-cf]
  if str  = "nk4" [report nk4-cf]
  if str  = "nk5" [report nk5-cf]
  if str  = "nk6" [report nk6-cf]
  error (word str  " is not an implemented coherency function!!!!")
end

to make-cfs
  set poss-bs poss-of-len num-beliefs
  set zero-cf table:make
  foreach poss-bs [? ->
    table:put zero-cf ? 0
  ]
  set incr-cf table:make
  let incr-vals n-values (1 + num-beliefs) [? -> 2 * (? / num-beliefs) - 1]
;;  let incr-vals [-1 -0.333 0.333 1]
  foreach poss-bs [? ->
    table:put incr-cf ? item (sum ?) incr-vals
  ]
  set decr-cf table:make
  let decr-vals n-values (1 + num-beliefs) [? -> -2 * (? / num-beliefs) + 1]
;;  let decr-vals [1 0.333 -0.333 -1]
  foreach poss-bs [? ->
    table:put decr-cf ? item (sum ?) decr-vals
  ]
  set sing-cf table:make
  let sing-vals sentence [0 1 -0.5] n-values (num-beliefs + 1) [-1]
  set sing-vals sublist sing-vals 0 (num-beliefs + 1)
;;  let sing-vals [0 1 -0.5 -1]
  foreach poss-bs [? ->
    table:put sing-cf ? item (sum ?) sing-vals
  ]
  set dble-cf table:make
  let dble-vals sentence [-1 0 1] n-values (num-beliefs + 1) [-1]
  set dble-vals sublist dble-vals 0 (num-beliefs + 1)
  foreach poss-bs [? ->
    table:put dble-cf ? item (sum ?) dble-vals
  ]
  set fixr-cf table:make
  foreach poss-bs [? ->
    table:put fixr-cf ? (random-float 2) - 1
  ]
  set scep-cf table:make
  let scep-vals sentence [1] n-values num-beliefs [-1]
  foreach poss-bs [? ->
    table:put scep-cf ? item (sum ?) scep-vals
  ]
  set yell-cf table:make
  foreach poss-bs [? ->
    table:put yell-cf ? (ifelse-value (item 0 ? = 1) [1] [-1])
  ]
  set anti-yell-cf table:make
  foreach poss-bs [? ->
    table:put anti-yell-cf ? (ifelse-value (item 0 ? = 1) [-1] [1])
  ]
  if num-beliefs > 1 [
    set blue-cf table:make
    foreach poss-bs [? ->
      table:put blue-cf ? (ifelse-value (item 1 ? = 1) [1] [-1])
    ]
    set anti-blue-cf table:make
    foreach poss-bs [? ->
      table:put anti-blue-cf ? (ifelse-value (item 1 ? = 1) [-1] [1])
    ]
    set blue-yell-cf table:make
    foreach poss-bs [? ->
      table:put blue-yell-cf ? (ifelse-value (item 1 ? = 1) [ifelse-value (item 0 ? = 1) [0] [1]]
                                                            [ifelse-value (item 0 ? = 1) [-1] [0]])
    ]
    set yell-blue-cf table:make
    foreach poss-bs [? ->
      table:put yell-blue-cf ? (ifelse-value (item 1 ? = 1) [ifelse-value (item 0 ? = 1) [0] [-1]]
                                                             [ifelse-value (item 0 ? = 1) [1] [0]])
    ]
    set blue-or-yell-cf table:make
    foreach poss-bs [? ->
      table:put blue-or-yell-cf ? (ifelse-value (item 1 ? = 1) [ifelse-value (item 0 ? = 1) [-1] [1]]
                                                             [ifelse-value (item 0 ? = 1) [1] [0]])
    ]
  ]
  if num-beliefs > 2 [
    set red-cf table:make
    foreach poss-bs [? ->
      table:put red-cf ? (ifelse-value (item 2 ? = 1) [1] [-1])
    ]
  set anti-red-cf table:make
    foreach poss-bs [? ->
      table:put anti-red-cf ? (ifelse-value (item 2 ? = 1) [1] [-1])
    ]
  ]
  if num-beliefs > 2 [
    set blue-red-cf table:make
    foreach poss-bs [? ->
      table:put blue-red-cf ? (ifelse-value (item 2 ? = 1) [ifelse-value (item 1 ? = 1) [0] [-1]]
                                                           [ifelse-value (item 1 ? = 1) [1] [0]])
    ]
  ]
    if num-beliefs > 2 [
    set red-blue-cf table:make
    foreach poss-bs [? ->
      table:put red-blue-cf ? (ifelse-value (item 2 ? = 1) [ifelse-value (item 1 ? = 1) [0] [1]]
                                                           [ifelse-value (item 1 ? = 1) [-1] [0]])
    ]
  ]
  set nk0-cf nk-table 0
  if num-beliefs > 1 [
    set nk1-cf nk-table 1
    if num-beliefs > 2 [
      set nk2-cf nk-table 2
      if num-beliefs > 3 [
        set nk3-cf nk-table 3
        if num-beliefs > 4 [
        set nk4-cf nk-table 4
        if num-beliefs > 5 [
          set nk5-cf nk-table 5
          if num-beliefs > 6 [
          set nk6-cf nk-table 6
  ]]]]]]
end

to-report nk-table [k]
  if k > num-beliefs [error (word "k=" k " bigger than num-beliefs, " num-beliefs)]
  let vl 0
  let nkfn table:make
  let nk-vals n-values num-beliefs [n-values (2 ^ (k + 1)) [random-float 1]]
  foreach poss-bs [p ->
    set vl 0
    foreach seq 0 (num-beliefs - 1) 1 [? ->
      set vl vl + item (num-of (bit-of ? (k + 1) p)) (item ? nk-vals)
    ]
    set vl vl / num-beliefs
    table:put nkfn p (2 * vl - 1)
  ]
  report nkfn
end

to-report bit-of [s l lis]
  let opl []
  let ll length lis
  foreach seq s (s + l - 1) 1 [? ->
    set opl lput (item (? mod ll) lis) opl
  ]
  report opl
end

to-report rand-val
  report (random-float 2) - 1
end

to do-hist
  set-current-plot "Hist. of Hamming distances"
  let hamm-list map [? -> (hamming-dist first ? second ?) / num-beliefs] n-values 10000 [(list ([beliefs] of one-of turtles) ([beliefs] of one-of turtles))]
  set av-hamming mean hamm-list
  set sd-hamming standard-deviation hamm-list
  set max-hamming ceiling max hamm-list
  set-plot-x-range 0 1 + (1 / num-beliefs)
  set-plot-pen-interval 1 / num-beliefs
  histogram hamm-list

  set-current-plot "Hist. of Linked Hamming distances"
  let linked-hamm-list map [? -> (hamming-dist first ? second ?) / num-beliefs] n-values 10000 [beliefs-of-ends-of one-of links]
  set av-linked-hamming mean linked-hamm-list
  set sd-linked-hamming standard-deviation linked-hamm-list
  set max-linked-hamming ceiling max linked-hamm-list
  set-plot-x-range 0 1 + (1 / num-beliefs)
  set-plot-pen-interval 1 / num-beliefs
  histogram linked-hamm-list

  set-current-plot "Belief Set Prevalence"
  set-plot-x-range 0 1 + max [num-of beliefs] of turtles
  set-plot-pen-interval 1
  histogram [num-of beliefs] of turtles

  set-current-plot "Degree Distribution"
  set-plot-pen-interval 1
  set-plot-x-range 0 max list 1 max [num-links] of turtles
  histogram [num-links] of turtles

  set-current-plot "Hist. of type-1 Ops"
  set-plot-pen-interval 1 / 7
  set-plot-x-range -1 (1 + 1 / 7)
  set-current-plot-pen "1s"
  histogram [opinion-from beliefs] of type1s
  set-current-plot "Hist. of type-2 Ops"
  set-plot-pen-interval 1 / 7
  set-plot-x-range -1 (1 + 1 / 7)
  set-current-plot-pen "2s"
  histogram [opinion-from beliefs] of type2s
  set-current-plot "Hist. of type-3 Ops"
  set-plot-pen-interval 1 / 7
  set-plot-x-range -1 (1 + 1 / 7)
  set-current-plot-pen "3s"
  histogram [opinion-from beliefs] of type3s
end

to-report hamming-dist [vec1 vec2]
  report sum (map [[?1 ?2] -> ifelse-value (?1 = ?2) [0] [1]] vec1 vec2)
end

to-report beliefs-of-ends-of [lnk]
  report list
     [beliefs] of [end1] of lnk
     [beliefs] of [end2] of lnk
end

to-report name
  report (word self)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to a-a-GO end

to go
  ;; if time is done stop simulation
  reset-timer
  if max-time > 0 [if ticks  > max-time [tidy-up stop]]

  set end-tick ticks
  set any-change? false
  set num-bels-ch 0
  set num-links-ch 0

  ask links [
    set color white
    set shape "default"
    set rejected? false
  ]
  ask turtles [set rejected-from nobody]
  ask links [maybe-transmit-a-belief]
  ask turtles [maybe-drop-a-belief]
  if mut-prob-power < 0 [
    ask turtles [maybe-mutate-a-belief]
  ]

  if link-change-mode = "change" [ask turtles [maybe-change-a-link]]
  if link-change-mode = "drop & add" [
    ask turtles [maybe-drop-a-link]
    ask turtles [maybe-add-a-link]
  ]
  if not (link-change-mode = "none")
    [ask turtles [check-min-num-nodes]]
  ;;  ask turtles [maybe-swap-a-link]
  if fix-num-links? [fix-num-links]
  if adapt-n-links? [adapt-n-links]

  if spread-every > 0
    [if ticks mod spread-every = 0 [spread]]

  ifelse any-change?
    [set no-change-for 0]
    [set no-change-for no-change-for + 1]

  if auto-stop? [
    if no-change-for > 100 [set end-tick ticks - 100 do-hist stop]
    if length remove-duplicates [beliefs] of turtles = 1 [do-hist stop]
  ]

  set num-bels-ch-disp num-bels-ch
  set cumm-bel-ch cumm-bel-ch + num-bels-ch
  set num-links-ch-disp num-links-ch
  set cumm-link-ch cumm-link-ch + num-links-ch
  if Hist? [do-hist]
  if calc-stats? [calc-stats]
  set num-components length nw:weak-component-clusters
  set secs-per-tick timer
  tick
end

to tidy-up
  do-hist
  calc-stats
  spread-lots
end

to maybe-transmit-a-belief
  let transmitted? false
  let rejected-now? false
  let n1 end1
  let n2 end2
  if bi-dir-arcs? [
    let ends list end1 end2
    set n1 random-member ends
    set n2 first remove n1 ends
  ]
  let bel-pos -1
  ask n1 [
    if some-beliefs? [
      set bel-pos a-belief-pos-from beliefs
    ]
  ]
  if bel-pos < 0 [stop]
  ask n2 [
    if item bel-pos beliefs = 0 [
      if prob (copy-rate / arcs-per-node) [
        let new-beliefs set-pos bel-pos beliefs
        let new-coherence table:get cfn new-beliefs
        ifelse prob scale scaling-fn (new-coherence - coherence) [
          if act-ch-bel? [
            set beliefs new-beliefs
            update-appearence
            set transmitted? true
            set num-bels-ch num-bels-ch + 1
          ]
        ] [
          set rejected-from n1
          set rejected-now? true
        ]
      ]
    ]
  ]
  if rejected-now? [
    set shape "double"
    set rejected? true
  ]
  if transmitted? [set color item bel-pos base-colour-list]
end

to-report coherency-diff [ps]
  let with-bel replace-item ps beliefs 1
  let coh-with table:get cfn with-bel
  let without-bel replace-item ps beliefs 0
  let coh-without table:get cfn without-bel
  report scale scaling-fn (coh-with - coh-without)
end

to-report coherency-with [ag]
  let bel-pos random num-beliefs
  let ag-bel -1
  ask ag [
    set ag-bel item bel-pos beliefs
  ]
  let new-beliefs replace-item bel-pos beliefs ag-bel
  let new-coherence table:get cfn new-beliefs
  report scale scaling-fn (new-coherence - coherence)
end

to-report num-links
  ifelse bi-dir-arcs?
    [report count my-links]
    [report count my-out-links]
end

to fix-num-links
  while [count links < num-arcs] [
    ask one-of turtles [add-link]  ;; at moment is pretty arbitrary with no bias towards those with fewer links
  ]
  while [count links > num-arcs] [
    ask one-of turtles [drop-link-for-sure]  ;; at moment is pretty arbitrary with no bias towards those with more links
  ]
end

to adapt-n-links
  let fct 0.00001 * (abs (count links - num-arcs)) ^ 2
;;  let f10 (fct / 10)
  if count links < num-arcs [
    set prob-drop-link max list 0 precision (prob-drop-link - fct) 5
;;    set prob-new-link precision (prob-new-link + f10) 6
  ]
  if  count links > num-arcs [
    set prob-drop-link min list 1 precision (prob-drop-link + fct) 5
;;    set prob-new-link precision (prob-new-link - f10) 6
  ]
end

to maybe-swap-a-link
  ;; none ATM -- idea is that the ends of two rejected links are swapped
end

to maybe-drop-a-link
  if prob prob-drop-link [
    drop-link
  ]
end

to maybe-change-a-link
  if prob prob-drop-link [
    drop-link-for-sure
    if prob prob-repl-link [add-link]
  ]
end

to-report candidate-drop
  if change-link-on = "last rejected copy" [report link-from rejected-from]
  if change-link-on = "never" [report nobody]
  if change-link-on = "any" [report one-of my-links-in]
  let oth one-of my-neighbors
  if change-link-on = "incoherency of rand" [
    ifelse oth != nobody [
      ifelse prob coherency-with oth
        [report nobody]
        [report link-from oth]
    ] [report nobody]
  ]
  let oths my-links-in with [rejected?]
  if change-link-on = "rejected link" [report one-of oths]
  if change-link-on = "rejected then any" [
    ifelse any? oths
      [report one-of oths]
      [report one-of my-links-in]
  ]
  let oth-list sort-by [[?1 ?2] -> first ?1 < first ?2] map [? -> list coherency-with ? ?] [self] of my-neighbors
  if change-link-on = "prob incoherency" [
    ifelse not empty? oth-list
      [report link-from second first oth-list]
      [report nobody]
  ]
  if change-link-on = "most incoherent" [
    ifelse not empty? oth-list
      [report link-from second (rnd:weighted-one-of-list oth-list [? -> first ?])]
      [report nobody]
  ]
  error (word change-link-on " not implemented yet as a change-link-on option!")
end

to drop-link
  let lnk candidate-drop
  if lnk != nobody [
    ask lnk [die]
    set num-links-ch num-links-ch + 1
  ]
end

to drop-link-for-sure
  let lnk candidate-drop
  if lnk = nobody [set lnk one-of links]
  ask lnk [die]
  set num-links-ch num-links-ch + 1
end

to-report my-links-in
  ifelse bi-dir-arcs? [
    report my-links
  ]  [
    report my-in-links
  ]
end

to maybe-add-a-link
  if prob prob-new-link [
    add-link
  ]
end

to check-min-num-nodes
  while [count my-neighbors < min-num-links] [
    add-link
  ]
end

to add-link
   let newoth nobody
   if prob prob-fof-first [set newoth one-of fof-cand-nodes]
   if newoth = nobody [set newoth one-of any-cand-nodes]
   if newoth = nobody [error (word self " has no candidates for linking!")]
   set num-links-ch num-links-ch + 1
   make-link newoth
end

to-report fof-cand-nodes
  report other ((join-sets [my-neighbors] of my-neighbors) with [not linked-to? myself])
end

to-report any-cand-nodes
  report other turtles with [not linked-to? myself]
end

to check-node-num-links [ag]
  ask ag [check-num-links]
end

to check-num-links
  if count my-neighbors < arcs-per-node [
    error (word self " has less than " arcs-per-node " in links!")
  ]
end

to repair-in-links
  while [count my-neighbors < arcs-per-node] [add-link]
end

to maybe-mutate-a-belief
  if prob (10 ^ mut-prob-power) [
    let pos random num-beliefs
    set beliefs replace-item pos beliefs (1 - item pos beliefs)
    update-appearence
  ]
end

to-report some-beliefs?
  report (sum beliefs) > 0
end

to-report no-beliefs?
  report (sum beliefs) = 0
end

to-report set-pos [pos lis]
  report replace-item pos lis 1
end

to-report clear-pos [pos lis]
  report replace-item pos lis 0
end

to-report a-belief-pos-from [bels]
  if empty? bels [error "Trying to find the position of the 1's in the empty list!!!"]
  report random-member pos-of-1s-in bels
end

to-report pos-of-1s-in [bels]
  report map [? -> length bels - 1 - ?] po bels
end

to-report po [bels]
  if empty? bels [report []]
  ifelse first bels = 1
    [report fput (length bels - 1) (po but-first bels)]
    [report po but-first bels]
end

to maybe-drop-a-belief
  if no-beliefs? [stop]
  let bel-pos a-belief-pos-from beliefs
  let new-beliefs clear-pos bel-pos beliefs
  let new-coherence table:get cfn new-beliefs
  if prob drop-rate [
     if prob (scale scaling-fn (new-coherence - coherence)) [
       if act-ch-bel? [
         set beliefs new-beliefs
         set num-bels-ch num-bels-ch + 1
         update-appearence
       ]
     ]
  ]
end

to-report opinion-from [bel]
  report table:get opinion-fn bel
end

to-report num-of [bels]
  if empty? bels [report 0]
  report first bels + 2 * num-of but-first bels
end

to-report scale [labl val]
  ;; linear maps [-1, 1] to [0, 1]
  if labl = "linear" [report (val + 1) / 2]
  ;; ramped flat in [-1, -0.5] and [0.5, 1]
  if labl = "ramped" [report min list 1 max list 0 val]
  ;; sudden a step fn
  if labl = "step" [report ifelse-value (val > 0) [1] [0]]
  ;; very weak logistic
  if labl = "very weak logistic" [report 1 / (1 + 1.5 ^ (-1 * val))]
  ;; soft logistic
  if labl = "weak logistic" [report 1 / (1 + 2 ^ (-1 * val))]
  ;; medium logistic
  if labl = "med logistic" [report 1 / (1 + 2 ^ (-1 * 2 * val))]
  ;; strong logistic
  if labl = "strong logistic" [report 1 / (1 + 2 ^ (-1 * 10 * val))]
  error (word labl " is not an inplemented scaling function!!!")
end

to-report safe-item [pos lis]
  if pos > (length lis - 1) [report 0]
  report item pos lis
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; STATS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to a-a-STATS end

to calc-stats
  set num-0-beliefs (count turtles with [(safe-item 0 beliefs) = 1]) / num-agents
  if num-beliefs > 1
     [set num-1-beliefs  (count turtles with [(safe-item 1 beliefs) = 1]) / num-agents]
  if num-beliefs > 2
     [set num-2-beliefs  (count turtles with [(safe-item 2 beliefs) = 1]) / num-agents]
  if num-beliefs > 3
     [set num-3-beliefs  (count turtles with [(safe-item 3 beliefs) = 1]) / num-agents]
  if num-beliefs > 4
     [set num-4-beliefs  (count turtles with [(safe-item 4 beliefs) = 1]) / num-agents]
  if num-beliefs > 5
     [set num-5-beliefs  (count turtles with [(safe-item 5 beliefs) = 1]) / num-agents]
  if num-beliefs > 6
     [set num-6-beliefs  (count turtles with [(safe-item 6 beliefs) = 1]) / num-agents]
  if num-beliefs > 7
     [set num-7-beliefs  (count turtles with [(safe-item 7 beliefs) = 1]) / num-agents]
  if num-beliefs > 8
     [set num-8-beliefs  (count turtles with [(safe-item 8 beliefs) = 1]) / num-agents]
  if num-beliefs > 9
     [set num-9-beliefs  (count turtles with [(safe-item 9 beliefs) = 1]) / num-agents]
  if num-beliefs > 10
     [set num-10-beliefs  (count turtles with [(safe-item 10 beliefs) = 1]) / num-agents]
  if num-beliefs > 11
     [set num-11-beliefs  (count turtles with [(safe-item 11 beliefs) = 1]) / num-agents]
  if num-beliefs > 12
     [set num-12-beliefs  (count turtles with [(safe-item 12 beliefs) = 1]) / num-agents]
  set num-no-beliefs (count turtles with [(safe-item 0 beliefs) = 0 and (safe-item 1 beliefs) = 0]) / num-agents
  set num-0+1-beliefs (count turtles with [(safe-item 0 beliefs) = 1 and (safe-item 1 beliefs) = 1]) / num-agents
  set av-opinion mean [opinion-from beliefs] of turtles
  set sd-opinion standard-deviation [opinion-from beliefs] of turtles
  let lnks no-links
  if num-type1s > 0 [
    set av-opinion-type1 mean [opinion-from beliefs] of type1s
    set sd-opinion-type1 standard-deviation [opinion-from beliefs] of type1s
    set lnks links-of type1s
    set het-prop-type1 calc-hetero-type-links lnks
    set consensus-type1 calc-cons type1s
    set prop-l-consensus-type1 calc-cons-links lnks
    set insularity-type1 calc-insularity type1s
  ]
  if num-type2s > 0 [
    set av-opinion-type2 mean [opinion-from beliefs] of type2s
    set sd-opinion-type2 standard-deviation [opinion-from beliefs] of type2s
    set lnks links-of type1s
    set het-prop-type2 calc-hetero-type-links lnks
    set consensus-type2 calc-cons type2s
    set prop-l-consensus-type2 calc-cons-links lnks
    set insularity-type2 calc-insularity type2s
  ]
  if num-type3s > 0 [
    set av-opinion-type3 mean [opinion-from beliefs] of type3s
    set sd-opinion-type3 standard-deviation [opinion-from beliefs] of type3s
    set lnks links-of type1s
    set het-prop-type3 calc-hetero-type-links lnks
    set consensus-type3 calc-cons type3s
    set prop-l-consensus-type3 calc-cons-links lnks
    set insularity-type3 calc-insularity type3s
  ]

  set prop-consensus calc-cons turtles
  set pi-l calc-het-l
  set pi-a calc-het-a
  set pi-t calc-het-t
  set het-prop calc-hetero-type-links links
  set prop-l-consensus calc-cons-links links

  set av-num-links count links / count turtles
  set glob-clustering global-clustering-coefficient turtles links
end

to-report calc-het-l
  let lnks sort links
  let tot 0
  foreach lnks [? ->
    set tot tot + hamming-dist [beliefs] of ([end1] of ?) [beliefs] of ([end2] of ?)
  ]
  report tot / count links
end

to-report calc-het-a
  let num count turtles
  report calc-tot-het turtles / num-l turtles
end

to-report calc-tot-het [ags]
  set ags sort ags
  let tot 0
  while [not empty? ags] [
    set tot tot + hamming-sum first ags but-first ags
    set ags but-first ags
  ]
  report tot
end

to-report num-l [ags]
  let num count ags
  report num * (num + 1) / 2
end

to-report hamming-sum [f rst]
  let tot 0
  foreach rst [? ->
    set tot tot + hamming-dist ([beliefs] of f) ([beliefs] of ?)
  ]
  report tot
end

to-report calc-het-t
  report (calc-tot-het type1s + calc-tot-het type2s + calc-tot-het type3s) / (num-l type1s + num-l type2s + num-l type3s)
end

to-report calc-hetero-type-links [linkset]
  let tot 0
  ask linkset [
    if [breed] of end1 = [breed] of end2
      [set tot tot + 1]
  ]
  report tot / count linkset
end

to-report calc-cons [ags]
  let freq-pair-list map [? -> list count ags with [beliefs = ?] ?] possible-states
  set freq-pair-list sort-by [[?1 ?2] -> first ?1 > first ?2] freq-pair-list
  set consensus first first freq-pair-list
  report consensus / count ags
end

to-report calc-cons-links [linkset]
  let tot 0
  ask linkset [
    if [beliefs] of end1 = [beliefs] of end2
      [set tot tot + 1]
  ]
  report tot / count linkset
end

to-report links-of [ags]
  let lnks no-links
  ask ags [
    set lnks (link-set lnks my-links)]
  report lnks
end

to-report calc-insularity [ags]
  let lnks links-of ags
  let num-internal-links count lnks with [member? end1 ags and member? end2 ags]
  report num-internal-links / count lnks
end

to op-graphs
  export-all-plots filename
end

to-report global-clustering-coefficient [ags lnks]
  nw:set-context ags lnks
  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of ags
  let triplets sum [ count my-links * (count my-links - 1) ] of ags
  report closed-triplets / triplets
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;   General set of utilities - many not used here!   ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to a-a-GEN-UTILS end

to-report remove-list [remlis lis]
  let opl lis
  foreach remlis [? ->
    set opl remove ? lis
  ]
  report opl
end

to-report n-colours [n]
  ;; produces a list of n random visible colurs (not too near black)
  report n-values n [(list (10 + random 245) (10 + random 245) (10 + random 245))]
end

to-report poss-of-len [dim]
  if dim <= 0 [report [[]]]
  let poss-minus1 poss-of-len (dim - 1)
  report sentence (map [? -> fput 0 ?] poss-minus1) (map [? -> fput 1 ?] poss-minus1)
end

to pause
  if not user-yes-or-no? (word "Continue?") [error "User halted simulation!!"]
end

to-report showpause [inp]
  if not user-yes-or-no? (word "Value is: " inp " -- Continue?") [error "User halted simulation!!"]
  report inp
end

to ipat [p1 p2]
  inspect patch p1 p2
end

to ith
  ask turtles-here [inspect self]
end

to-report link-breed [p1 p2]
  let pl []
  ask p1 [set pl sort my-links]
  ask p2 [
    let p2l sort my-links
    set pl filter [? -> member? ? p2l] pl
  ]
  if empty? pl [report "none"]
  report [breed] of (random-member pl)
end

to-report random-member [ls]
  report item (random length ls) ls
end

to-report prob [p]
  report random-float 1 < p
end

to-report subtract-list [lis1 lis2]
  report filter [? -> not member? ? lis2] lis1
end

to-report safeSubList [lis srt en]
  let len length lis
  if en < 1 or srt > len [report []]
  report subList lis max list 0 srt min list en len
end

to-report safe-n-of [nm lis]
  if is-list? lis [if length lis >= nm [report n-of nm lis]]
  if is-agentset? lis [if count lis >= nm [report n-of nm lis]]
  report lis
end

to-report safe-one-of [lis]
  report safe-n-of 1 lis
end

to-report join-sets [setlist]
  if empty? setlist [report no-turtles]
  let opset no-turtles
  report (turtle-set first setlist join-sets but-first setlist)
end

to-report flatten-once [lis]
  let op-list []
  foreach lis [l ->
    foreach l [li -> set op-list fput li op-list]
  ]
  report op-list
end

to-report minList [lis1 lis2]
  report (map [[?1 ?2] -> min list ?1 ?2] lis1 lis2)
end

to-report maxList [lis1 lis2]
  report (map [[?1 ?2] -> max list ?1 ?2] lis1 lis2)
end

to-report sumList [lis1 lis2]
  report (map [[?1 ?2] -> ?1 + ?2] lis1 lis2)
end

to-report sdList [sqLis sumLis numLis]
  report (map [[?1 ?2] -> sqrt max (list 0 ((?1 / numLis) - ((?2 / numLis) ^ 2)))] sqLis sumLis)
end

to-report fputIfNew [exLisLis newLis]
  report (map [[?1 ?2] -> ifelse-value (member? ?2 ?1) [?1] [fput ?2 ?1]] exLisLis newLis)
end

to-report csv-string-to-list [str]
  let lis []
  while [not empty? str] [
    set lis fput next-value str lis
    set str after-next str
  ]
  report reverse lis
end

to-report after-next [str]
  let pos-comma position "," str
  if pos-comma != false [report subString str (pos-comma + 1) length str]
  report ""
end

to-report next-value [str]
  let pos-comma position "," str
  if pos-comma != false [
    report read subString str 0 pos-comma
    ]
  report read str
end

to-report read [str]
  set str strip-spaces str
  if empty? str [report nobody]
    ifelse is-string-a-number? str
      [report read-from-string str]
      [report str]
end

to-report strip-spaces [str]
  report strip-leading-spaces strip-trailing-spaces str
end

to-report strip-leading-spaces [str]
  if empty? str [report str]
  if first str != " " [report str]
  report strip-leading-spaces but-first str
end

to-report is-string-a-number? [str]
  if empty? str
    [report false]
  report is-nonempty-string-a-number? str
end

to-report is-nonempty-string-a-number? [str]
  if empty? str [report true]
  let ch first str
  if ch = "." [report is-string-digits? but-first str]
  if not is-str-digit? ch [report false]
  report is-nonempty-string-a-number? but-first str
end

to-report is-string-digits? [str]
  if empty? str [report true]
  let ch first str
  if not is-str-digit? ch [report false]
  report is-string-digits? but-first str
end

to-report is-str-digit? [ch]
  ifelse ch >= "0" and ch <= "9"
    [report true]
    [report false]
end

to-report strip-trailing-spaces [str]
  if empty? str [report str]
  if last str != " " [report str]
  report strip-trailing-spaces but-last str
end

to-report insert [itm ps lis]
  report (sentence sublist lis 0 ps (list itm) sublist lis ps (length lis))
end

to-report insertAfter [itm ps lis]
  report insert itm (ps + 1) lis
end

to-report num-nodes [lis]
  report length nodes-in lis
end

to-report nodes-in [lis]
  if not is-list? lis [report (list lis)]
  let op-list []
  foreach lis [? -> set op-list append op-list nodes-in ?]
  report op-list
end

to-report second [lis]
  report item 1 lis
end

to-report third [lis]
  report item 2 lis
end

to XXX
  let tt 1
  set tt tt - 1
  set tt 1 / tt
end

to-report showPass [arg]
  show arg
  report arg
end

to-report posBiggest [lis]
  report position (reduce [[?1 ?2] -> ifelse-value (?1 >= ?2) [?1] [?2]] lis) lis
end

to-report allPos [expr]
  let oplis [[]]
  foreach but-first (n-values (length expr) [? -> ?]) [? ->
    let ps ?
    let posLis allPos (item ps expr)
    set opLis append (map [?1 -> fput ps ?1] posLis) opLis
  ]
  report opLis
end

to-report replaceAtPos [posList baseExpr insExpr]
  if posList = [] [report insExpr]
  report replace-item (first posList) baseExpr (replaceAtPos (but-first posList) (item first posList baseExpr) insExpr)
end

to-report atPos [posList expr]
  if empty? posList [report expr]
  report atPos but-first posList item (first poslist) expr
end

to-report append [list1 list2]
  if empty? list1 [report list2]
  report fput (first list1) (append (but-first list1) list2)
end

to-report selectProbilistically [charList numList]
  report item (chooseProbilistically numList) charList
end

to-report chooseProbilistically [numList]
  report findPos (random-float 1) cummulateList scaleList numList
end

to-report chooseReverseProbilistically [numList]
  if length numList = 1 [report 0]
  report findPos (random-float 1) cummulateList reverseProbList scaleList numList
end

to-report reverseProbList [numList]
  report map [?1 -> 1 - ?1] numList
end

to-report cummulateList [numList]
  report cummulateListR numList 0
end

to-report cummulateListR [numList cumm]
  if empty? numList [report []]
  let newCumm cumm + first numList
  report fput newCumm cummulateListR but-first numList newCumm
end

to-report scaleList [numLis]
  if empty? numLis [report numLis]
  let sumLis sum numLis
  if sumLis = 0 [report numLis]
  report map [?1 -> ?1 / sumLis] numLis
end

to-report findPos [vl numList]
  report findPosR vl numList 0
end

to-report findPosR [vl numList  ps]
  if empty? numList [report ps]
  if vl <= (first numList) [report ps]
  report findPosR vl but-first numList (1 + ps)
end

to-report freqOfIn [lis allList]
  report reduce [[?1 ?2] -> fput (numOfIn ?2 lis) ?1 ] (fput [] allList)
end

to-report freqOf [lis]
  if empty? lis [report []]
  let sort-lis sort lis
  let red-lis sort remove-duplicates lis
  let op-lis red-lis
  let num-lis []
  let cnt 0
  foreach sort-lis [? ->
    ifelse ? = first red-lis
      [set cnt cnt + 1]
      [set num-lis fput cnt num-lis
       set cnt 1
       set red-lis but-first red-lis]
  ]
  set num-lis fput cnt num-lis
  report pair-list (reverse num-lis) op-lis
;;  report pair-list reverse num-lis red-lis
  ;;  report fput (list (numOfIn first lis lis) (first lis)) (freqOf remove first lis lis)
end

to-report freqRep [lis]
  report sort-by [[?1 ?2] -> first ?1 > first ?2] filter [? -> first ? > 1] freqOf lis
end

to-report numOfIn [itm lis]
  report length (filter [? -> itm = ?] lis)
end

to-report patchesToDist [dist]
  if dist = 0 [report self]
  let patchList []
  foreach seq (-1 * dist) dist 1 [? ->
    let xc ?
      foreach seq (-1 * dist) dist 1 [
        set patchList fput patch-at xc ? patchList
      ]
  ]
  report patch-set patchList
end

to-report individualsToDist [dist]
  report turtles-on patchesToDist dist
end

to-report distBetween [x1 y1 x2 y2]
  report (max list abs (x1 - x2) abs (y1 - y2))
;;  report sqrt (((x1 - x2) ^ 2) + ((y1 - y2) ^ 2))
end

to-report seq [from upto stp]
  report n-values (1 + ceiling ((upto - from) / stp)) [? -> from + ? * stp]
end

to-report safeDiv [numer denom]
  if denom = 0 and numer = 0 [report 1]
  if denom = 0 [report 0]
  report numer / denom
end

to-report flip-bit [ps bitList]
  report replace-item ps bitList (1 - (item ps bitList))
end


to showList [lis]
  foreach but-last lis [? -> type ? type " "]
  print last lis
end


to-report is-divisor-of [num den]
  report (0 = (num mod den))
end

to-report pair-list [lis1 lis2]
  report (map [[?1 ?2] -> list ?1 ?2] lis1 lis2)
end

to-report depth [lis]
  if not is-list? lis [report 0]
  if empty? lis [report 0]
  report 1 + max map [? -> depth ?] lis
end

to-report empty-as
  report no-turtles
end

to-report exists [obj]
  if is-turtle-set? obj [report any? obj]
  report obj != nobody
end

to-report pick-at-random-from-list [lis]
  report item random length lis lis
end

to tv [str val]
  if trace? [output-print (word str "=" val)]
end

to-report normal-dist [x mn sd]
  report exp (-0.5 * ((x - mn) / sd) ^ 2) / (sd * sqrt (2 * pi))
end

to-report careful-item [ps lis str]
  let rs 0
  carefully
    [set rs item ps lis]
    [output-print (word "str" ": no position " ps " in: " lis)]
  report rs
end
@#$#@#$#@
GRAPHICS-WINDOW
186
10
659
484
-1
-1
15.0
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
30
0
30
1
1
1
ticks
30.0

BUTTON
137
509
192
542
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

BUTTON
194
509
249
542
NIL
go\n
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
4
332
174
365
prop-of-type1
prop-of-type1
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
2
72
175
105
num-agents
num-agents
10
500
50.0
10
1
NIL
HORIZONTAL

BUTTON
250
509
305
542
step
go\nspread-lots\ncalc-stats\ndo-hist
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
666
57
795
90
arcs-per-node
arcs-per-node
1
10
3.0
1
1
NIL
HORIZONTAL

CHOOSER
4
367
129
412
Coherence-Fn-Type1
Coherence-Fn-Type1
"zero" "yell" "anti-yell" "blue" "anti-blue" "blue-yell" "yell-blue" "blue-or-yell" "red" "anti-red" "blue-red" "red-blue" "incr" "decr" "scep" "sing" "dble" "indr" "fixr" "nk0" "nk1" "nk2" "nk3" "nk4" "nk5" "nk6"
0

CHOOSER
5
496
130
541
Coherence-Fn-Type2
Coherence-Fn-Type2
"zero" "yell" "anti-yell" "blue" "anti-blue" "blue-yell" "yell-blue" "blue-or-yell" "red" "anti-red" "blue-red" "red-blue" "incr" "decr" "scep" "sing" "dble" "indr" "fixr" "nk0" "nk1" "nk2" "nk3" "nk4" "nk5" "nk6"
6

SLIDER
2
107
174
140
num-beliefs
num-beliefs
1
13
2.0
1
1
NIL
HORIZONTAL

SLIDER
2
185
174
218
copy-rate
copy-rate
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
2
220
174
253
drop-rate-prop-of-copy
drop-rate-prop-of-copy
0
2
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
3
142
175
175
init-prob-belief
init-prob-belief
0
1
0.5
0.01
1
NIL
HORIZONTAL

SWITCH
666
92
795
125
bi-dir-arcs?
bi-dir-arcs?
0
1
-1000

CHOOSER
665
10
796
55
initial-topology
initial-topology
"random" "regular" "star" "planar" "small world" "preferential attachment"
0

SLIDER
3
255
173
288
mut-prob-power
mut-prob-power
-10
0
-3.0
1
1
NIL
HORIZONTAL

PLOT
263
607
542
768
Prevalence of Beliefs
time
consensus
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"yellows" 1.0 0 -4079321 true "" "plot (count turtles with [(item 0 beliefs) = 1]) / num-agents"
"blues" 1.0 0 -14070903 true "" "if num-beliefs > 1 [\nplot (count turtles with \n           [(safe-item 1 beliefs) = 1]) \n                           / num-agents]"
"reds" 1.0 0 -5298144 true "" "if num-beliefs > 2 [\nplot (count turtles with \n           [(safe-item 2 beliefs) = 1]) \n                           / num-agents]"
"orange" 1.0 0 -955883 true "" "if num-beliefs > 3 [\nplot (count turtles with \n           [(safe-item 3 beliefs) = 1]) \n                           / num-agents]"
"brown" 1.0 0 -6459832 true "" "if num-beliefs > 4 [\nplot (count turtles with \n           [(safe-item 4 beliefs) = 1]) \n                           / num-agents]"
"green" 1.0 0 -10899396 true "" "if num-beliefs > 5 [\nplot (count turtles with \n           [(safe-item 5 beliefs) = 1]) \n                           / num-agents]"
"lime" 1.0 0 -13840069 true "" "if num-beliefs > 6 [\nplot (count turtles with \n           [(safe-item 6 beliefs) = 1]) \n                           / num-agents]"
"turquoise" 1.0 0 -14835848 true "" "if num-beliefs > 7 [\nplot (count turtles with \n           [(safe-item 7 beliefs) = 1]) \n                           / num-agents]"
"cyan" 1.0 0 -11221820 true "" "if num-beliefs > 8 [\nplot (count turtles with \n           [(safe-item 8 beliefs) = 1]) \n                           / num-agents]"
"violet" 1.0 0 -8630108 true "" "if num-beliefs > 9 [\nplot (count turtles with \n           [(safe-item 9 beliefs) = 1]) \n                           / num-agents]"
"magenta" 1.0 0 -5825686 true "" "if num-beliefs > 10 [\nplot (count turtles with \n           [(safe-item 10 beliefs) = 1]) \n                           / num-agents]"
"pink" 1.0 0 -2064490 true "" "if num-beliefs > 11 [\nplot (count turtles with \n           [(safe-item 11 beliefs) = 1]) \n                           / num-agents]"
"black" 1.0 0 -16777216 true "" "if num-beliefs > 12 [\nplot (count turtles with \n           [(safe-item 12 beliefs) = 1]) \n                           / num-agents]"

CHOOSER
4
413
129
458
Scaling-Fn-Type1
Scaling-Fn-Type1
"linear" "ramped" "step" "very weak logistic" "weak logistic" "med logistic" "strong logistic"
4

CHOOSER
5
542
130
587
Scaling-Fn-Type2
Scaling-Fn-Type2
"linear" "ramped" "step" "very weak logistic" "weak logistic" "med logistic" "strong logistic"
6

PLOT
801
191
1012
311
Belief Set Prevalence
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

SWITCH
364
509
472
542
auto-stop?
auto-stop?
1
1
-1000

PLOT
1017
191
1233
311
Degree Distribution
Degree
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"degree" 1.0 1 -16777216 true "" ""

PLOT
802
314
1013
434
Hist. of Hamming distances
Distance
Frequency
0.0
3.0
0.0
1.0
true
false
"" ""
PENS
"Freq" 1.0 1 -16777216 true "" ""

SWITCH
655
523
745
556
Hist?
Hist?
1
1
-1000

INPUTBOX
1
10
176
70
title
bilateral vs zero
1
0
String

INPUTBOX
137
544
200
604
max-time
1000.0
1
0
Number

PLOT
1017
313
1233
433
Hist. of Linked Hamming distances
Distance
Frequency
0.0
1.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 1 -14439633 true "" ""

CHOOSER
1119
558
1232
603
Opinion-Fn-Name
Opinion-Fn-Name
"zero" "yell" "anti-yell" "blue" "anti-blue" "blue-yell" "yell-blue" "blue-or-yell" "red" "anti-red" "blue-red" "red-blue" "incr" "decr" "scep" "sing" "dble" "indr" "fixr" "nk0" "nk1" "nk2" "nk3" "nk4" "nk5" "nk6"
5

PLOT
911
436
1071
556
Hist. of type-2 Ops
Opinion
Frequency
-1.0
1.0
0.0
10.0
true
false
"" ""
PENS
"2s" 1.0 1 -16777216 true "" ""

PLOT
859
608
1233
768
Opinion Lines
NIL
NIL
0.0
10.0
-1.0
1.0
true
false
"ask type1s [\n  create-temporary-plot-pen name\n  set-current-plot-pen name\n  set-plot-pen-color cyan + 3\n]\nask type2s [\n  create-temporary-plot-pen name\n  set-current-plot-pen name\n  set-plot-pen-color red + 3\n]" "set-current-plot-pen \"av\"\nplot mean [opinion-from beliefs] of turtles\n;; ask type1s [\n;;  set-current-plot-pen name\n;;  plot opinion-from beliefs\n;; ]\n;; ask type2s [\n;;  set-current-plot-pen name\n;;  plot opinion-from beliefs\n;;]"
PENS
"av" 1.0 0 -16777216 true "" ""

SLIDER
666
207
798
240
init-prob-drop-link
init-prob-drop-link
0
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
481
509
536
542
Spread
spread-lots
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
667
242
797
275
prob-repl-link
prob-repl-link
0
1
0.95
0.01
1
NIL
HORIZONTAL

MONITOR
367
560
417
605
Num L
count links
0
1
11

SWITCH
577
565
682
598
calc-stats?
calc-stats?
1
1
-1000

MONITOR
419
560
469
605
NIL
pi-a
3
1
11

MONITOR
472
560
522
605
NIL
pi-l
3
1
11

MONITOR
525
559
575
604
pi-t
pi-t
3
1
11

MONITOR
135
395
185
440
s/tck
secs-per-tick
2
1
11

CHOOSER
666
160
797
205
link-change-mode
link-change-mode
"drop & add" "change" "none"
0

SLIDER
668
277
797
310
prob-new-link
prob-new-link
0
0.1
0.01
0.0005
1
NIL
HORIZONTAL

SLIDER
668
312
797
345
min-num-links
min-num-links
0
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
311
559
365
604
Het Lnks
het-prop
3
1
11

SWITCH
132
735
260
768
fix-num-links?
fix-num-links?
1
1
-1000

SLIDER
539
508
653
541
spread-every
spread-every
0
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
259
558
309
603
L. Cons.
prop-l-consensus
3
1
11

PLOT
801
10
1235
189
Agreement
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"L.Cons" 1.0 0 -5825686 true "" "if ticks > 0 [plot prop-l-consensus]"
"L.Hetero" 1.0 0 -13791810 true "" "if ticks > 0 [plot het-prop]"
"Cons." 1.0 0 -3844592 true "" "if ticks > 0 [plot prop-consensus]"

PLOT
546
608
854
769
Diversity
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"pi-a" 1.0 0 -16777216 true "" "if ticks > 0 [plot pi-a]"
"pi-l" 1.0 0 -14835848 true "" "if ticks > 0 [plot pi-l]"
"pi-t" 1.0 0 -7858858 true "" "if ticks > 0 [plot pi-t]"

MONITOR
206
558
256
603
Cons
prop-consensus
2
1
11

CHOOSER
667
347
798
392
change-link-on
change-link-on
"last rejected copy" "never" "any" "incoherency of rand" "rejected link" "rejected then any" "prob incoherency" "most incoherent"
0

MONITOR
156
653
206
698
Cu.B.Ch
cumm-bel-ch / (ticks * num-agents)
3
1
11

MONITOR
209
654
259
699
Cu.L.Ch
cumm-link-ch / (ticks * num-arcs)
3
1
11

BUTTON
97
605
152
638
CS
calc-stats
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
748
435
908
555
Hist. of type-1 Ops
NIL
NIL
-1.0
1.0
0.0
10.0
true
false
"" ""
PENS
"1s" 1.0 1 -16777216 true "" ""

MONITOR
701
559
751
604
AvOp
av-opinion
2
1
11

MONITOR
752
559
802
604
SdOp
sd-opinion
2
1
11

MONITOR
805
560
855
605
AvOp 1
av-opinion-type1
2
1
11

MONITOR
856
560
906
605
SdOp 1
sd-opinion-type1
2
1
11

MONITOR
909
560
959
605
AvOp 2
av-opinion-type2
2
1
11

MONITOR
960
560
1010
605
SdOp 2
sd-opinion-type2
2
1
11

SWITCH
133
700
261
733
adapt-n-links?
adapt-n-links?
0
1
-1000

MONITOR
155
606
205
651
k
av-num-links
2
1
11

MONITOR
208
606
259
651
Av.Clust
glob-clustering
3
1
11

BUTTON
690
488
745
521
Hist
do-hist
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
4
291
172
324
act-ch-bel?
act-ch-bel?
0
1
-1000

SLIDER
666
126
796
159
init-sep-prob
init-sep-prob
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
5
460
177
493
prop-of-type2
prop-of-type2
0
1
0.1
0.01
1
NIL
HORIZONTAL

CHOOSER
4
640
130
685
Coherence-Fn-Type3
Coherence-Fn-Type3
"zero" "yell" "anti-yell" "blue" "anti-blue" "blue-yell" "yell-blue" "blue-or-yell" "red" "anti-red" "blue-red" "red-blue" "incr" "decr" "scep" "sing" "dble" "indr" "fixr" "nk0" "nk1" "nk2" "nk3" "nk4" "nk5" "nk6"
5

CHOOSER
4
688
130
733
Scaling-Fn-Type3
Scaling-Fn-Type3
"linear" "ramped" "step" "very weak logistic" "weak logistic" "med logistic" "strong logistic"
5

MONITOR
4
592
93
637
prop-of-type3
1 - prop-of-type1 - prop-of-type2
2
1
11

PLOT
1074
434
1234
554
Hist. of type-3 Ops
NIL
NIL
-1.0
1.0
0.0
10.0
true
false
"" ""
PENS
"3s" 1.0 1 -16777216 true "" ""

BUTTON
307
509
362
542
10
repeat 10 [go]\nspread-lots\ncalc-stats\ndo-hist
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1012
559
1062
604
AvOp 3
av-opinion-type2
2
1
11

MONITOR
1064
559
1114
604
SdOp 3
sd-opinion-type3
2
1
11

MONITOR
668
432
745
477
Prob Drop
prob-drop-link
2
1
11

SLIDER
667
395
797
428
prob-fof-first
prob-fof-first
0
1
1.0
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a simulation model which explores the combination of (socially influenced) belief change and social network change. The cognitive model is inspired by Thagard's theories (e.g. Explanatory Coherence 1989).  This model is an extension of the one described in:

Edmonds, B. (2012) Modelling Belief Change in a Population Using Explanatory Coherence, Advances in Complex Systems, 15(6):1250085.  DOI: 10.1142/S0219525912500853

See the slides describing this model at: http://www.slideshare.net/BruceEdmonds/a-model-of-social-and-cognitive-coherence

## TO RUN IT

1. Install Netlogo (version 6 onwards)
1. Adjust parameters using sliders
1. Press 'setup'
1. Press 'go'

## PARAMETERS and OPTIONS

### General

* *title* -- string used for recoding data (e.g. the captured movie)
* *num-agents* -- number of agents in the simulation
* *num-beliefs* -- number of atomic beliefs around
* *init-prob-belief* -- probability that agents hold each of the atomic beliefs at the start

### Belief Change

* *copy-prob* -- the probability that a (random) belief from one agent will be attempted to be copied to anther during the copy process
* *drop-rate-prop-of-copy* -- the drop-rate = *copy-prob* x *drop-rate-prop-of-copy* --  the drop-rate is the probability that an individual will do the drop process once (per simulation tick)
* *mut-prob-power* -- this is the power of 10 of the probability that a random belief of an agent is flipped each time click (so -3 is a probability of 0.001)
* *act-ch-bel?* -- a switch for turning off belief change - if false it goes through the motions but the beliefs are not changed (does not affect the drop-link process)

###Types of agent

* *prop-of-type1* -- Proportion of agents that are of type 1
* *Coherence-Fn-Type1* -- The coherency function for type 1 agents (see list below)
* *Scaling-Fn-Type1* -- The scaling function for coherence for type 1 agents (see list below)
* *prop-of-type2* -- Proportion of agents that are of type 2
* *Coherence-Fn-Type2* -- The coherency function for type 1 agents (see list below)
* *Scaling-Fn-Type2* -- The scaling function for coherence for type 1 agents (see list below)
* *prop-of-type3* -- Proportion of agents that are of type 2 = 1 - prop-of-type1 - prop-of-type2
* *Coherence-Fn-Type3* -- The coherency function for type 1 agents (see list below)
* *Scaling-Fn-Type3* -- The scaling function for coherence for type 1 agents (see list below)
* *Opinion-Fn-Name* -- The function that is used for recovering the opinion from the beliefs of agents which is then averaged for the global Opinion

### Output

* *movie-every* -- if this is 0 no movies are generated, if > 0 then a frame is captured every period specified by this and the movie saved when simulation reaches max-time
* *spread-every* -- if this is 0 no visual spreading of nodes occurs, if > 0 then nodes are spread to reveal the network structure every period specified by this (this slows the simulation up)

### Initial Social Network

* *initial-topology* -- choose between a number of initial topologies: "random", "regular", "star", "planar", "small world" or "preferential attachment"
* *arcs-per-node* -- how many arcs lead into each node on average
* *bi-dir-arcs?* -- whether the acrs are uni- or bi-directional
* *init-sep-prob* -- the probability that types only link to their own kind at the start

### Link Change

* *link-change-mode* -- how links are dropped/changed, one of: "drop & add", "change" or "none". *drop & add* drops links separately from making new links, *change* when a link is dropped a new link into the target node is made, if *none* the link change processes are turned off
* *init-prob-drop-link* -- the probability of dropping a link under the conditions specified by *change-link-on*
* *prob-repl-link* -- in the case of *link-change-mode* = "change" then this is the probability the dropped link is replaced
* *prob-new-link* -- in case of *link-change-mode* = "drop & add" then this is probability of adding a new random link
* *min-num-links* -- If the number of links of any node drops below this then a new random link is added into it
* *change-link-on* -- the choices controlling which link might be changed: "last rejected copy" (a link where a belief copy process failed to be accepted), "never" (never change links), "any" (a random in link), "coherency of rand" (pick an in-link at random then only if it is incoherent), "rejected link" (a random link from all those labelled as "rejected?", regardless of the direction of the rejected copy), "rejected then any" (same as last if oen exists otherwise one at random), "prob incoherency" (probilitistically on levels of incoherency), and "most incoherent" (drop the link to the agent most incoherent to self).
* *add-fof-first?* -- when making a new link are friends-of-friends picked or another chosen at random

### Maintain link density options

Cludges to ensure the ration of arcs to nodes remains (roughly) constant

* *adapt-n-links?* -- if number of links is not the target number (*num-of-nodes* x *arcs-per-node*) adapt the level of link-dropping to bring this back
* *fix-num-links?* -- if number of links is not the target number (*num-of-nodes* x *arcs-per-node*) either add random links or kill random links to bring it back

### Stopping

* *max-time* -- the time at which the simulation will stop (if 0 never stops)
* *auto-stop?* -- automatically stop if there have been no belief changes over the last 100 time clicks

### Output and statistic switches

* *Hist?* -- whether to calculate and display histograms (which slows the simulation). Histograms are always done when simulation ends.
* *calc-stats?* -- whether to calculate various statistics during the simulation (which slows the simulation). Statistics are always calculated for the end of the last time period of the simulation.

## COHERENCY FUNCTIONS

These are the functions that can be chosen for the Coherency Functions for the 3 types, or for the Opinion Function. Some of these refer to atomic beliefs: yellow, blue, red etc.

* *zero* -- coherency is always 0
* *yell* -- is 1 if yellow is believed, -1 otherwise
* *anti-yell* -- is -1 if yellow is believed, 1 otherwise
* *blue* -- is 1 if blue is believed, -1 otherwise
* *anti-blue* -- is -1 if blue is believed, 1 otherwise
* *blue-yell* -- is 1 if blue and not yellow believed, is -1 if yellow and not blue believed, 0 otherwise
* *yell-blue* -- is 1 if yellow and not blue believed, is -1 if blue and not yellow believed, 0 otherwise
* *blue-or-yell* --
* *red* -- is 1 if red is believed, -1 otherwise
* *anti-red* -- is -1 if red is believed, 1 otherwise
* *blue-red* -- is 1 if blue and not red believed, is -1 if red and not blue believed, 0 otherwise
* *red-blue* -- is 1 if red and not blue believed, is -1 if blue and not red believed, 0 otherwise
* *incr* -- is 1 if all beliefs are held, -1 if none, scaled between these for other numbers
* *decr* -- is -1 if all beliefs are held, 1 if none, scaled between these for other
* *scep* -- is 1 if no beliefs held, -1 otherwise
* *sing* -- is 1 if one belief is held, 0 if no beliefs held, -0.5 if two beliefs held, -1 otherwise
* *dble* -- is 0 if one belief, 1 if two beliefs, -1 otherwise
* *indr* -- construct a random coherency function for each agent of that type, with the value for each possible belief subset assigned a random number between -1 and 1
* *fixr* -- construct a random coherency function that is common to all agents of that type, with the value for each possible belief subset assigned a random number between -1 and 1
* *nk0* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=0
* *nk1* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=1
* *nk2* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=2
* *nk3* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=3
* *nk4* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=4
* *nk5* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=5
* *nk6* -- construct a random coherency function that is common to all agents of that type, with the values taken from a NK function with k=5

## SCALING FUNCTIONS

These are the functions one can choose between in the Sclaning Function Options of the types, all mapping a change in coherency (max = +2 change, min is -2 change)

* *linear* -- linearly maps [-1, 1] to [0, 1]
* *ramped* -- ramped but flat in [-1, -0.5] and [0.5, 1]
* *step* -- 0 for < 0 and 1 for > 0
* *very weak logistic* -- a very flat logistic curve, only a very weak connection between increase/decrease in coherence and the probability of change
* *weak logistic* -- a flat logistic curve, only a weak connection between increase/decrease in coherence and the probability of change
* *med logistic* -- a logist curve with a strong but not deterministic connection between increase/decrease in coherence and the probability of change
* *strong logistic* -- a logistic curve that is almost a step function, but not quite deterministic

## OUTPUTS

### World View

The current nodes and links are shown, the spread in 2D space is not significant and only done to make the networks easier to understand.

### Monitors

* *s/tck* -- how many seconds the last simulation tick took
* *Prob Drop* -- the probability of dropping a link (will only change from *init-prob-drop-link* if *adapt-n-links?* is true)
* *Prop-of-type3* -- Proportion of agents that are of type 2 = 1 - prop-of-type1 - prop-of-type2
* *Cons* -- The greatest proportion of nodes with the same belief set
* *L.Cons.* -- The proportion of links whose ends have the same belief sets
* *Het Links* -- The average heterogeneity of beliefs at ends of links
* *Num L* -- The number of links
* *pi-a* -- The average diversity between the belief sets of all agents
* *pi-l* -- he average diversity between the belief sets of all linked agents
* *pi-t* -- he average diversity between the belief sets of all agents of the same type
* *k* -- the number of links
* *Av.Clust* -- Average of the local clustering coefficient of all nodes
* *Cu.B.Ch* -- Cummulatie number of belief changes
* *Cu.L.Ch* -- Cummulative number of link changes
* *AvOp* -- Average Opinion as calculated by the function specified by *Opinion-Fn-Name*
* *SdOp* -- Standard Deviation of the agent Opinions as calculated by the function specified by *Opinion-Fn-Name*
* *AvOp 1* -- Average Opinion as calculated by the function specified by *Opinion-Fn-Name* of type 1s
* *SdOp 1* -- Standard Deviation of the agent Opinions as calculated by the function specified by *Opinion-Fn-Name* of type 1s
* *AvOp 2* -- Average Opinion as calculated by the function specified by *Opinion-Fn-Name* of type 2s
* *SdOp 2* -- Standard Deviation of the agent Opinions as calculated by the function specified by *Opinion-Fn-Name* of type 2s
* *AvOp 3* -- Average Opinion as calculated by the function specified by *Opinion-Fn-Name* of type 3s
* *SdOp 3* -- Standard Deviation of the agent Opinions as calculated by the function specified by *Opinion-Fn-Name* of type 3s

### Graphs

If clac-stats? is false some of these do not show any changes.

* *Agreement* -- Graphs *Cons*, *L.Cons* and *Het Links* as described above
* *Prevalance of Beliefs* -- Shows the proportion of all nodes that believe the atomic beliefs
* *Diversity* -- Graphs *pi-a*, *pi-l* and *pi-t* as described above
* *Opinion Lines* -- Shows the AvOP as described above

### Histograms

These are only displayed if Hist? is on (except at mac-time)

* *Belief Set Prevalence* -- Sorts belief sets into a sequence with more beliefs as higher and less as lower then shows a histogram of the prevalence of the various sets in the population
* *Degree Distribution* -- shows the distribution of number of links nodes have
* *Hist. of Hamming distances* -- Shows the distribution of hamming distances between all pairs of nodes
* *Hist. of Linked Hamming distances* -- Shows the distribution of hamming distances between all linked nodes
* *Hist. of type-1 Ops* -- shows the distribution of opinions of type-1 agents using the function specified by *Opinion-Fn-Name*
* *Hist. of type-2 Ops* -- shows the distribution of opinions of type-2 agents using the function specified by *Opinion-Fn-Name*
* *Hist. of type-3 Ops* -- shows the distribution of opinions of type-3 agents using the function specified by *Opinion-Fn-Name*

### Other statistics calculated

In addition to those displayed in the graphs and monitors the following are also calculated:

* *end-tick* -- the last tick on which anything happened (belief change, link change)
* *num-components* -- the number of disconnected networks that have formed
* *num-bels-ch* -- the number of beliefs that changed that time click
* *num-links-ch* -- the number of linnks that changed that time click

## CREDITS AND REFERENCES

Bruce Edmonds 9th July 2016
bruce@edmonds.name
http://bruce.edmonds.name --
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Brexiteers properties fixed" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexiteers properties&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <steppedValueSet variable="prop-of-type2" first="0" step="0.05" last="0.3"/>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
      <value value="&quot;step&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Brexit base" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexit base&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Floaters properties fixed" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexit base&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;very weak logistic&quot;"/>
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Remainers Properties fixed" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Remainers Properties&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <steppedValueSet variable="prop-of-type2" first="0" step="0.05" last="0.3"/>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initial conds fixed" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;initial conds&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="init-prob-belief" first="0" step="0.25" last="1"/>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="init-sep-prob" first="0" step="0.25" last="1"/>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Brexiteers properties - 1 fixed" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexiteers properties 1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <steppedValueSet variable="prop-of-type2" first="0" step="0.05" last="0.3"/>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
      <value value="&quot;step&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Floaters properties - 1 fixed" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Floaters properties - 1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;very weak logistic&quot;"/>
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Remainers Properties - 1 fixed" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Remainers Properties -1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <steppedValueSet variable="prop-of-type2" first="0" step="0.05" last="0.3"/>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;weak logistic&quot;"/>
      <value value="&quot;med logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initial conds - 1 fixed" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;initial conds&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="init-prob-belief" first="0" step="0.25" last="1"/>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="init-sep-prob" first="0" step="0.25" last="1"/>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Brexit Run 5" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexit Run 5&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Brexit 100" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;Brexit Run 7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="contrast bilateral vs neutral pop" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>drop-rate</metric>
    <metric>num-0-beliefs</metric>
    <metric>num-1-beliefs</metric>
    <metric>num-2-beliefs</metric>
    <metric>num-3-beliefs</metric>
    <metric>num-4-beliefs</metric>
    <metric>av-opinion</metric>
    <metric>sd-opinion</metric>
    <metric>av-opinion-type1</metric>
    <metric>av-opinion-type2</metric>
    <metric>av-opinion-type3</metric>
    <metric>sd-opinion-type1</metric>
    <metric>sd-opinion-type2</metric>
    <metric>sd-opinion-type3</metric>
    <metric>consensus-type1</metric>
    <metric>consensus-type2</metric>
    <metric>consensus-type3</metric>
    <metric>het-prop-type1</metric>
    <metric>het-prop-type2</metric>
    <metric>het-prop-type3</metric>
    <metric>insularity-type1</metric>
    <metric>insularity-type2</metric>
    <metric>insularity-type3</metric>
    <metric>prop-l-consensus-type1</metric>
    <metric>prop-l-consensus-type2</metric>
    <metric>prop-l-consensus-type3</metric>
    <metric>consensus</metric>
    <metric>end-tick</metric>
    <metric>num-components</metric>
    <metric>prop-l-consensus</metric>
    <metric>prop-consensus</metric>
    <metric>het-prop</metric>
    <metric>pi-a</metric>
    <metric>pi-l</metric>
    <metric>pi-t</metric>
    <metric>num-bels-ch</metric>
    <metric>num-links-ch</metric>
    <metric>cumm-bel-ch</metric>
    <metric>cumm-link-ch</metric>
    <metric>av-num-links</metric>
    <metric>glob-clustering</metric>
    <enumeratedValueSet variable="title">
      <value value="&quot;bilateral vs zero&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="act-ch-bel?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt-n-links?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-fof-first">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arcs-per-node">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="auto-stop?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bi-dir-arcs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calc-stats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-link-on">
      <value value="&quot;last rejected copy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type1">
      <value value="&quot;blue-or-yell&quot;"/>
      <value value="&quot;zero&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type2">
      <value value="&quot;yell-blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coherence-Fn-Type3">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="copy-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-rate-prop-of-copy">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix-num-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hist?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-belief">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-prob-drop-link">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-sep-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-topology">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-change-mode">
      <value value="&quot;drop &amp; add&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-num-links">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-every">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut-prob-power">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-beliefs">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Opinion-Fn-Name">
      <value value="&quot;blue-yell&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-new-link">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-repl-link">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-of-type2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type1">
      <value value="&quot;weak logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type2">
      <value value="&quot;strong logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scaling-Fn-Type3">
      <value value="&quot;med logistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-every">
      <value value="0"/>
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

double
0.0
-0.2 1 4.0 4.0
0.0 1 4.0 4.0
0.2 1 4.0 4.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
