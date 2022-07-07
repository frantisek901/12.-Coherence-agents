__includes ["reset.nls"]
;; Version Notes
;; V1.1.68.3
;; base version to include Social Identity approaches as outlined in Bruce's abstract including some distance measures to determine "goodness" of run
;; a) positive identity: party choice is based on a given identity (eg. nativist, green)
;; b) opinion dynamics with fixed network, different topologies
;; c) opinion dynamics with dynamic network (new random links, new links with friends of friends, drop links with people you disagree with a lot)
;; d) negative identity: party choice is determined more by who you are against (eg. exclude nativist parties, pick randomly between the rest)
;; for a and d need model paramters that determine proportion of identity voters
;; -- this model version covers options b and c
;; -- changes made:
;; * added distance measures to evaluate democratic efficiency, i.e. measure distance of voters to the current government --> section distance measures
;;   so far we have:
;;   i) mean distance in all dimensions ("rational choice"),
;;   ii) proportion of voters with distance in all dimensions less than 1 likert category away from gov. position ("happy" voters)
;;   iii) mean distance in two most important dimensions ("fast and frugal")
;;   iv) proportion of voters with distance in most important dimensions less than 1 likert catergory away ("happy" voters)
;; * measures are displayed in a new plot "Distance measures"
;; * calculation of distance measures needs representation of "the government"; this is an additional (invisible) agent with positions as average of the coalition partners
;;   new breed government, new global variable the-gov, parties have new attriubute in-government?, new procedures change-gov, create-a-gov, possible-gov, government-positions,
;;     in-government, government-position-on, government-vote-share
;;   a new government is created after an election, i.e. at the very beginning of the simulation and at step 208; possible-gov returns a coalition of the largest parties
;; * added a choice of social network topologies --> section social network stuff
;;   so far we have: homophily-based political discussion (= network as before), regular random, Erdös-Rényi random, preferential attachment
;;   -- links now record the result of interactions in new attributes outcome (list of 1s (agreement) and -1s (disagreement) -- one list only since outcome is same for both)
;;      and change (list of two lists of seven elements to record position change per issue for both partners, in case we want to base link drop on distance moved)
;;   -- new chooser "network-type" and 3 new sliders for network parameters "number-of-friends" (mean number of links), "new-link-prob" (probability to form a new link),
;;      "drop-threshold" (number of disagreements necessary before link is dropped)
;;   -- new monitors to check number of dropped links / new friend links / new random links / voters without links and a plot to show total number of links
;;   -- new procedures to create the networks: create-homophily-political-discussion-network, create-regular-random-network, create-erdos-renyi-network, create-pref-attachement-network
;;      plus some additional small functions
;; * changed procedure to influence friends to now use social network to find interaction partners instead of random pairings: influence-friend-fixed-network
;;   -- inside that also changed test if interaction happens: combine it for both agents, instead of having each of them check separately
;;      (reason: it doesn't make much sense that one of them is ready for interaction and changes their position whereas the other
;;       one is not ready and doesn't change but obviously still talked to the other guy somehow)

;; V1.1.68.2
;; animation-related changes // left as a side branch

;; V1.1.68.1
;; -- changed add-some-noise to only return values between (-0.5,0.5) instead of before (-1,1) since that changed the underying data by moving people's answers to a different category
;; -- added grid-based cluster analysis to check how polarised people become (procedures grid-cluster-analysis, cyes, cno)


;; V1.1.68
;; -- changing party colours to coincide with current Austrian party colours: ÖVP cyan, FPÖ blue, NEOS pink, BZÖ orange, TS yellow
;; -- added more behaviour-space output functions to utils section
;; -- found BUG regarding voter-adapt-prob in influence-friend: used random 1 < voter-adapt-prob instead of random-float 1 < voter-adapt-prob !!
;;    --> this means parameter voter-adapt-prob was ignored and 'internally set' to 1, so people ALWAYS change with every discussion they have
;;    --> all my runs with voter-adapt-prob = 0.1 are actually runs with voter-adapt-prob = 1
;;    THIS BUG is also present in the old version (influence-friend-old) so God knows what other results I might have gotten...


; V1.1.67
;; -- adding to the opinion dynamics (still inspired by Schweighofer et al. 2020): instead of always compromising (= moving towards each other)
;;    when interacting, allow for disagreement (= moving away from each other)
;;    BUT: Schweighofer et al. drop the interaction threshold when introducing repulsion and say, if distance > threshold, this counts as disagreement
;;    and will push the agents further apart (problem is that by this stage in the paper they use polar coordinates and always move in all dimensions)
;; --> so we will have to define our own version of (dis-)agreement:
;;    only when agreeing on majority of other issues, do we move towards each other / otherwise, we move away (this is similar to Baldassarri/Bearman)
;; -- copied agree-on-other-issues?, agree-on-issue?, flavour from the pure BB-Polarisation model
;; -- changed adjust-position so that it takes the direction of movement as a parameter, added procedure sort-out-directions


;; V1.1.66
;; -- trying out a new interaction scheme based on opinion dynamics (see Schweighofer et al. 2020)
;;    this includes adding a new influence-friend (old version renamed influence-friend-old),
;;     adding a new attribute aff-level to voters to model level of affective involvement and initialise it in init-voters
;; -- added procedure draw-cross to draw x and y axes at 0 0

;; V1.1.65
;; -- another attmept at assigning voter strategies to voters better than randomly:
;;    we now use just a selection of the AUTNES survey (autnes2013_selection.csv), which contains only 1060 voters whose vote is known;
;;    they have been assigned a list of possible strategies in column 150. If we decide to use this (assign-from-data? set to on), we read it in
;;    when creating the voters and store it temporarily in my-strategy. After all voters have been created, we then assign their strategies,
;;    using the list of possible strategies and balancing this against the proportion of strategies defined in strategy-proportions
;;    Voters with just one strategy get this assigned, voters with more than one strategy get one of them randomly assigned unless there are still
;;    empty "spaces" for having strategy 2 and 2 is one of their strategies (confirmatory trumps everything)
;;
;; -- added new switch assign-from-data? to interface and new procedures assign-strategies, balance-bins

;; V1.1.6
;; -- store world after setup in a file so we can reset the simulation and run different experiments on the same setup
;;    ### does not work with export-world and import-world; there is a bug with table objects (I've raised it with the NetLogo guys)
;; -- add party leader's ideal points to change aggregator strategy (now: p-aggregator-new)
;;    this includes extending the party events from <list of ticks, party-name, our-issues> to <list of ticks, party-name, our-issues, ideal-pos, phi>
;;    (changing init-party-events and handle-party-events)

;; V1.1.5
;; -- removed bug from adjust-salience which allowed voters to have > 100% salience overall
;;    remaining questions: (a) how to handle people without important issues (there are 314 in the survey)?
;;                         (b) how big a change in salience do we want? And should it be constant (one value for all) or dependent on the current salience,
;;                             i.e. a greater change when salience is low and smaller when salience is already high?
;;                         (c) should both voters talking to each other adjust their salience or just the one with the lower salience?
;; -- added model parameter max-salience-change to experiment with question (b)
;; -- rearranged interface and added plot for issue salience of voters plus monitors for each party's vote share for easier reference

;; V1.1.4
;; -- add adjust-salience to change voters' issue importance whenever they talk about an issue
;; -- also added a counter for which topic a voter talked about (talked-about) and a plot showing which topics people talk about
;; -- #### YIKES: only just noticed that I completely forgot to actually call party events and issue salience changes from go in version 1.1.3 ## headdesk ###
;; -- #### good thing it does not really make a difference...

;; V1.1.3
;; -- add political events (leadership change of ÖVP)
;; -- add EuroBarometer data for choosing what to talk about

;; v1.1.2
;; -- aggregator strategy does not move on ALL dimensions, but only on the MOST IMPORTANT ones (copied from v1.25)
;; -- BehaviourSpace experiment february does not collect voter party changes, only collects position changes of parties who move (1,2,3)


;; v1.1.1 reverse-engineer a branch WITHOUT the new voter interaction based on Baldassari/Bearman 2007
;; -- fixed add-some-noise to only return values in interval (-1,1) to prevent changing people's answers to a different category

;; v 1.1: several bug fixes and small alterations/additions
;; -- fixed left-right position of voters (needed to be re-scaled from 0-10 to 1-5 to allow correct visualisation): procedure scale-down
;; -- added some output to interface
;; -- added possibility of dynamic network

;;V.1: changing implementation of opinions from factbase to 2d-array (with parties and issues as indices, voters' assessment of party vs issue as elements)
;;-- this will allow us to run experiments on the amazon cloud platform ## turns out it doesn't because we still need input files which amazon cloud can't handle

;; -------------------------------------------------------------------------------------------------------------------------------------------------------------
;; AUSTRIA PILOT MODEL OF THE PACE PROJECT, GRANT AGREEMENT ID: 822337, EU H2020
;;
;; This is Deliverable 2.2 of Work Package 2.
;;
;; Author: Ruth Meyer, Manchester Metropolitan University
;; in collaboration with our project partners at Salzburg University (Marco Fölsch, Martin Dolezal, Reinhard Heinisch)
;; -------------------------------------------------------------------------------------------------------------------------------------------------------------

;; Party strategies are taken from J. Muis & M. Scholte (2013): How to find the 'winning formula'? Acta Politica 48:22-46
;; they differentiate 4 types:
;; -- Sticker: party does not change position
;; -- Satisficer: party stops moving once aspired vote share is reached or surpassed and only starts moving again if loss > 25%
;; -- Aggregator: party moves towards average position of supporters
;; -- Hunter: party keeps moving in same direction if they gained vote share with last move, otherwise they turn around

;; Voter strategies are taken from R. Lau et al. (2018): Measuring voter decision strategies in political behavior and public opinion research
;;                                 Public Opinion Quarterly, 82:911-936
;; they differentiate 5 types:
;; -- Rational Choice: gather as much information as possible, compare all parties on all issues
;; -- Confirmatory: 'based on early affective-based socialization toward or against ... political parties, and a subsequent motivation
;;    to maintain cognitive consistency with the early learned affect. Party identification is generally the "lens" through which political
;;    information is selectively perceived. Information search is more passive than active" --> voting for party they feel closest to (partisanship)
;; -- Fast and frugal: try to be efficient, compare parties only on 1 or 2 (most important) issues
;; -- Heuristic-based: satisficing ("if one option meets my needs I will save time and go with it without really looking at others",
;;    choosing familiar candidate, follow recommendations of people/groups I trust, elimininating alternatives as soon as any negative information about them
;;    is encountered)
;; -- Go with gut: rely on intuition, make decisions based on what FEELS right

;; Other data is taken from surveys: AUTNES 2013 for voters, CHES 2014 for parties
;; have to align and select issues that both parties and voters find important and have a position on
;; -- found seven issues that work:
;;    party mips: "state intervention" "redistribution" "public services vs taxes" "immigration" "environment" "social lifestyle" "civil liberties vs. law and order"
;;    party vars: "econ_interven" "redistribution" "spendvtax" "immigrate_policy" "environment" "sociallifestyle" "civlib_laworder"
;;    voter mips: "economy" "welfare state" "budget" "immigration" "environmental protection" "society" "security"
;;    voter vars: "w1_q26_1" "w1_q26_2" "w1_q26_3" (add and reverse w1_q26_11/12 -> "a_immigration_index") "w1_q26_9" "w1_q26_6" "w1_q26_7"
;;    model issues: "economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order" "left-right"

;; also separate visualisation from voters/parties position on issues (and add noise only for vis)
;; -- this includes being able to pick which issues should be displayed on x- and y-axis
;; -- if people DON'T have a position on an issue, they need to be assigned 3 = neither agree or disagree (if assigned 0 they look as if they are extreme left)

extensions [csv table array profiler]

globals [
  voter-data party-data  ;; files with survey data
  party-names party-colours  ;; names and colours of parties
  ches-party-id-map     ;; mapping party ids used in CHES to party ids used in the model
  autnes-party-id-map   ;; mapping party ids used in AUTNES to party ids in model
  voter-mip-map         ;; map of voter mips used in the AUTNES survey to mips represented in the model
  voter-mip-probs       ;; distribution of mips derived from AUTNES
  party-mip-map         ;; map of party mips used in CHES to mips represented in the model
  party-mips            ;; list of most important issues for parties (taken from CHES)
  voter-mips            ;; matching list of most important issues for voters (taken from AUTNES) so that party-mips[i] = voter-mips[i]
  model-issues          ;; names for those issues used in the model
  current-display-issues  ;; which two issues are currently used to display the political landscape?
  strategy-probs        ;; probabilities for the strategies as defined by the model parameters
  ;; internal statistics
  pos-changes           ;; total number of position changes of voters
  op-changes            ;; total number of opinion changes
  inf-count             ;; total number of friend influences
  counter-dl            ;; number of dropped links
  counter-nfl           ;; number of new friend-of-friend links
  counter-nrl           ;; number of new random links
  ;; visualisation
  vis-turtle            ;; the invisible visualisation turtle
  ;; exogenous events
  issue-salience-ts     ;; time-series of issue salience taken from EuroBarometer, in the form <tick> <list of probabilities per issue>
                        ;; for ease of use we'll just stick this in a table
  current-issue-salience ;; the issue probs 'valid' for the current tick(s) --> these will be used to determine the most-relevant-issue!
  issue-salience-changeover ;; ticks when new probs are becoming 'valid' (stored here for ease of access)
  party-events          ;; important changes in party policies ### for now just the leadership change of the ÖVP, resulting in different most important issues
                        ;; form <tick> <list of party-name, our-issues>
  the-gov               ;; the abstract government party with positions as averages of the coalition partners
                        ;; for this to work easily, the-gov cannot be a party, has to be its own breed so that it isn't taken into account in any rc or ff voter decision-making!
  d-measures            ;; list of [average rational-choice dist to gov, proportion of voters <= average rc, average most-important dist to gov, proportion of voters <= average]
                        ;; stored in global variable so it only needs to be computed once per step, then used in 4 timelines in plot "distance measures"

  ;; only used in final "stats" bit, fortunately!
  av-positions-voters   ;; list of average positions of voters
  av-positions-parties  ;; list of average positions of voters
  av-dist-cv-voters     ;; average distance of voters to center (of voters' positions)
  av-dist-cv-parties    ;; average distance of parties to center (of voters' positions)
]

breed [voters voter]
breed [parties party]
breed [governments government]


voters-own [
  id
  age
  gender
  education-level
  income-situation
  residential-area
  political-interest
  closest-party
  degree-of-closeness
  pp           ;; party propensities (propensity to vote for SPÖ, ÖVP, FPÖ, BZÖ, Grüne, Team Stronach)
  prob-vote    ;; probability to go vote (between 0 I will definitely not vote and 10 I will definitely vote)
  mvf-party    ;; anticipated vote choice ("might vote for ")
  voted-party  ;; party actually voted for (second wave of survey, only part of participants did this)
  my-positions ;; stance on the modelled seven (eight) issues: 0: economy, 1: welfare state, 2: spend vs. taxes, 3: immigration, 4: environment, 5: society, 6: law and order, 7: left-right placement
  my-strategy  ;; type of voting decision-making strategy: 0 rational choice, 1: confirmatory, 2: fast and frugal, 3: heuristic-based, 4: go with gut 5: identitarian
  my-issues    ;; list of issues important to this voter
  my-saliences ;; list of weights for the issues (how important they are)
  my-opinions  ;; this is now implemented as a 2d array with issues x parties
               ;; this now uses a factbase with columns issue, party, measure
               ;; this allows us to see a time line of opinion change and maybe "forget" opinions?
               ;; map of issue <---> party (which party can deal best with the issue), this is used in decision-making and can be changed by media/friends influence
               ;; an opinion is a list [<issue> <party> <measure-of-fitness>]
               ;; measure-of-fitness is a value from [-2 -1 0 1 2] with meaning very bad/bad/neutral/good/very good
               ;; this allows to calculate an overall "fitness" value for each party (if so desired) over all issues (that are important to a voter)
               ;; --- voters can exchange opinions when talking to friends; depending on the importance voters place on an issue, they have more/less chance of
               ;;     convincing the other one of their opinion; the degree-of-closeness to their closest-party should also influence that?
  current-p    ;; party this voter currently would vote for (if they voted)
  positions    ;; translated issue positions into Netlogo "space" coordinates
  pos-history  ;; history of positions
  op-history   ;; history of opinions (as a list of opinions adopted over time)
  vote-history ;; history of party decisions (whenever current-p changes) (list of [<party> <tick>])
  talked-about ;; counts how often talked about which issue (## just to make times-talked-about faster ###)
  aff-level    ;; level of affective involvement (determined from political interest)
  talked-to    ;; history of whom I talked to
]

parties-own [
  id
  name
  our-positions ;; stance on the modelled seven (eight) issues: 0: economy, 1: welfare state, 2: spend vs. taxes, 3: immigration, 4: environment, 5: society, 6: law and order, 7: left-right placement
  our-issues    ;; most important issues for the party (data: mip1, mip2, mip3 --> all of them have to be mapped to the modelled issues)
  our-saliences ;; list of weights for the issues
  our-strategy  ;; type of party position adaptation strategy: 0 sticker 1 satisficer 2 hunter 3 aggregator
  vote-share    ;; history of the party's share of the votes, initialised with election result 2013 read in from file
  vs-change     ;; change to last election result (initialised with change to previous results read in from file)
  vs-aspiration-level ;; aspired level of vote share for strategy 'satisficing' (initialised with election result 2013 (or, if vs-change negative, result + change)
  h-dims        ;; dimensions chosen to move on for strategy 'hunter' (initialised with party's most important issue)
  h-dist        ;; distance for a move (0 if no move)
  h-heading     ;; history of headings
  positions     ;; translated issue positions into Netlogo space
  pos-history   ;; history of positions
  ideal-pos     ;; the party leader's ideal positions
  phi           ;; the factor deciding how much weight is put on ideal positions vs. supporters' positions
                ;; phi = 0 for usual aggregator strategy, i.e. only supporters' positions count
                ;; phi = 1 for ignoring supporters' positions entirely, only ideal positions count
  gov?          ;; true if party is forming the current government
]

governments-own [
  name
  coalition   ;; list of party ids
  vote-share              ;; should the gov adjust positions and vote-share continuously during the simulation?? #### Depends on what we want to do with the distance measures?
  positions
]

patches-own [
  traversed?
  cluster
]

links-own [
  outcomes  ;; to record discussion outcomes for the connected voters: 1 is agreement, -1 is disagreement
            ;; we'll keep track of every discussion in a list (need only one list since outcome is the same for both partners)
  change  ;; to record position change for the connected voters: a list of two elements, smaller who accesses front, larger who accesses back
          ;; we'll try out cumulative change; when it gets bigger than a certain threshold, the link will be dropped
          ;; PROBLEM with this: we need to separate the position change for the different issues, so it should be a list of 2 lists with 7 elements each
]

to setup
  clear-all
  if rnd-seed = 0 [set rnd-seed new-seed]
  random-seed rnd-seed
  ask patches [ set pcolor 5 ]

  set d-measures [0 0 0 0]
  set voter-data "./data/autnes2013_selection.csv"   ;;"./data/autnes2013_comma_3.csv" ;;
  set party-data "./data/Austria_2014_CHES_dataset.csv"

  set party-mips ["state intervention" "redistribution" "public services vs taxes" "immigration" "environment" "social lifestyle" "civil liberties vs. law and order"]
  set voter-mips ["economy" "welfare state" "budget" "immigration" "environmental protection" "society" "security"]
  set model-issues ["economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order" "left-right"] ;; added left-right placement because both parties and voters have a position on that

  set current-display-issues (list x-issue y-issue)
  ;; set strategy-proportions "[0.183 0.298 0.385 0.049 0.085]"
  set strategy-probs read-from-string strategy-proportions

  set party-names ["NULL" "SPO" "OVP" "FPO" "Greens" "BZO" "NEOS" "Team Stronach"]
  set party-colours [9 red cyan blue green orange pink yellow]
  ;; party ids/names from CHES are: 1301	SPO, 1302	OVP 1303 FPO 1304	GRUNE 1306 BZO 1307 NEOS 1310	TeamStronach
  ;; ches-party-id-map maps these to the parties represented in the model
  set ches-party-id-map [0 1301 1302 1303 1304 1306 1307 1310]
  ;; party names for AUTNES are ["NULL" "SPOE" "OEVP" "FPOE" "FP Kaernten" "BZOE" "The Greens" "KPOE" "NEOS/LIF/JULIS" "Team Stronach" "Pirates" "other party" "no party"]
  ;; autnes-party-id-map maps these to the parties represented in the model (FP Kärnten merged with FPÖ, KPÖ/Piraten/other/no party ignored = 0)
  set autnes-party-id-map [0 1 2 3 3 5 4 0 6 7 0 0 0]
  ;; use distribution of mips derived from AUTNES for voters with answer 77777 (multiple issues) to assign a mip
  set voter-mip-probs [0.4202 0.3089 0.0787 0.1072 0.0574 0.0128 0.0148]

  init-issue-saliences ;;init-issue-saliences-no-migration-crisis ;;
  init-party-events

  set pos-changes 0
  set op-changes 0
  set inf-count 0
  crt 1 [
    set hidden? true
  ]
  set vis-turtle one-of turtles ;; it's the only one around yet!

  init-voter-mip-map
  init-party-mip-map
;  show (word "creating parties ...")
  init-parties
;  show  (word "creating voters ...")
  init-voters
  assign-strategies  ;; assign voter decision strategies
;  show (word "creating social network ...")
  create-social-network
  ;; initialise party attributes for hunter strategy
  ask parties [
    init-h-dims
    init-h-directions
  ]
  ;; show (word "ready to roll!")
  reset-ticks

;  set _export-file (word "./state0/model_" rnd-seed ".csv")
;  export _export-file
;  random-seed rnd-seed
  ;export-world "./state0/model-state-0.csv"
  ;csv:to-file "./state0/voters.csv" [(list who my-issues my-strategy my-saliences positions aff-level)] of voters
  ;csv:to-file "./state0/links.csv" [(list end1 end2)] of links
end

to reset-state
;  setup
  reset _export-file ;;"./state0/model.csv"
  restore
  random-seed rnd-seed

;  if (global-variables = 0) [
;    reset-world "./experiments/PaCE_Austria_v1.1.67 world_secondRealisticResults.csv"
;  ]
;  restore-state
end

to init-party-events
  set party-events []
  ;; government formation at start of simulation
  ;; this relies on the parties having already been created and initialised with their vote shares
  set party-events lput [0 "government" [] [] 0] party-events
  ;; Sebastian Kurz became party leader of the ÖVP 10/05/2017 --> that's tick 94
  ;set party-events [[94 "OVP" ["immigration" "public services vs taxes" "state intervention"]]]
  ;; in 1-week steps, it's tick 189
  ;set party-events [[189 "OVP" ["immigration" "public services vs taxes" "state intervention"]]]
  ;set party-events [[189 "OVP" ["immigration" "public services vs taxes" "state intervention"] [3.8 3.3 4.3 4.6 3.8 3.4 4.2] 0]]   ;; phi = 0 means, ideal positions do not count
  set party-events lput [189 "OVP" ["immigration" "public services vs taxes" "state intervention"] [3.8 3.3 4.3 4.6 3.8 3.4 4.2] 0.4] party-events   ;; ### need to experiment with phi
                                                                                               ;; ideal position values taken from CHES 2019 (CHES 2017 did not contain Austria)
  set party-events lput [208 "government" [] [] 0] party-events
end

to handle-party-events
  if (not empty? party-events and first first party-events = ticks) [
    let current-event but-first first party-events ;; don't need the event tick anymore
    set party-events but-first party-events
    ;; check if government formation
    if (first current-event = "government") [
      change-gov
      stop
    ]
    ;; otherwise let the named party do its thing
    let mlist map [i -> convert-party-mip i] first but-first current-event  ;; parse mips
    let plist map [i -> translate-to-vis i] last but-last current-event     ;; translate ideal positions
    ask parties with [name = first current-event] [
      handle-party-mips mlist
      set ideal-pos plist
      set phi last current-event
    ]
  ]
end

to init-issue-saliences
  ;; values taken from EuroBarometer and adapted for the model, see Excel file EB_Most_Important_Issues_Austria.xlsx
  set issue-salience-ts table:make
  ;; ticks are representing 2-week periods
;  table:put issue-salience-ts 0   [0.3619 0.2361 0.0915 0.124 0.0778 0.009 0.0997]	
;  table:put issue-salience-ts 3   [0.4126 0.1848 0.1022 0.1302 0.0538 0.0036 0.1128]
;  table:put issue-salience-ts 12  [0.3918 0.1769 0.1423 0.1001 0.0651 0.0166 0.1072]
;  table:put issue-salience-ts 18  [0.3133 0.1521 0.1833 0.1481 0.065 0.0234 0.1148]
;  table:put issue-salience-ts 29	[0.317	0.1718	0.0942	0.1956	0.0908	0.0076	0.123]
;  table:put issue-salience-ts 37	[0.3312	0.1696	0.1338	0.1914	0.0702	0.0092	0.0946]
;  table:put issue-salience-ts 43	[0.3037	0.1574	0.0595	0.3119	0.0866	0.0054	0.0755]
;  table:put issue-salience-ts 55	[0.216	0.0776	0.0234	0.5615	0.0384	0.0076	0.0755]
;  table:put issue-salience-ts 69	[0.2386	0.1082	0.0342	0.4056	0.0616	0.0114	0.1404]
;  table:put issue-salience-ts 81	[0.2558	0.1512	0.0376	0.3609	0.0668	0.0196	0.1081]
;  table:put issue-salience-ts 95	[0.2413	0.1575	0.0602	0.3155	0.085	0.014	0.1265]
;  table:put issue-salience-ts 107 [0.2003	0.178	0.0684	0.2823	0.1208	0.0045	0.1457]
;  table:put issue-salience-ts 117 [0.1584	0.2398	0.0514	0.2947	0.0868	0.0158	0.1531]
  ;; ticks are representing 1-week periods
  table:put issue-salience-ts 0   [0.3619 0.2361 0.0915 0.124 0.0778 0.009 0.0997]	
  table:put issue-salience-ts 5   [0.4126 0.1848 0.1022 0.1302 0.0538 0.0036 0.1128]
  table:put issue-salience-ts 24  [0.3918 0.1769 0.1423 0.1001 0.0651 0.0166 0.1072]
  table:put issue-salience-ts 35  [0.3133 0.1521 0.1833 0.1481 0.065 0.0234 0.1148]
  table:put issue-salience-ts 58	[0.317	0.1718	0.0942	0.1956	0.0908	0.0076	0.123]
  table:put issue-salience-ts 74	[0.3312	0.1696	0.1338	0.1914	0.0702	0.0092	0.0946]
  table:put issue-salience-ts 85	[0.3037	0.1574	0.0595	0.3119	0.0866	0.0054	0.0755]
  table:put issue-salience-ts 110	[0.216	0.0776	0.0234	0.5615	0.0384	0.0076	0.0755]
  table:put issue-salience-ts 138	[0.2386	0.1082	0.0342	0.4056	0.0616	0.0114	0.1404]
  table:put issue-salience-ts 162	[0.2558	0.1512	0.0376	0.3609	0.0668	0.0196	0.1081]
  table:put issue-salience-ts 190	[0.2413	0.1575	0.0602	0.3155	0.085	0.014	0.1265]
  table:put issue-salience-ts 214 [0.2003	0.178	0.0684	0.2823	0.1208	0.0045	0.1457]
  table:put issue-salience-ts 233 [0.1584	0.2398	0.0514	0.2947	0.0868	0.0158	0.1531]

  set current-issue-salience table:get issue-salience-ts 0
  set issue-salience-changeover table:keys issue-salience-ts
end

to init-issue-saliences-no-migration-crisis
  set issue-salience-ts table:make
  table:put issue-salience-ts 0	  [0.354	0.2308	0.0895	0.1432	0.0761	0.0088	0.0976]
  table:put issue-salience-ts 5	  [0.4033	0.1806	0.0999	0.1498	0.0526	0.0036	0.1102]
  table:put issue-salience-ts 24	[0.385	0.1739	0.1398	0.1157	0.064	0.0163	0.1053]
  table:put issue-salience-ts 35	[0.3143	0.1526	0.1838	0.1454	0.0652	0.0235	0.1152]
  table:put issue-salience-ts 58	[0.3203	0.1736	0.0952	0.1871	0.0918	0.0077	0.1243]
  table:put issue-salience-ts 74	[0.3338	0.1709	0.1349	0.1851	0.0707	0.0093	0.0953]
  table:put issue-salience-ts 85	[0.3467	0.1796	0.0679	0.2147	0.0988	0.0061	0.0862]
  table:put issue-salience-ts 110	[0.3738	0.1344	0.0406	0.2409	0.0665	0.0131	0.1307]
  table:put issue-salience-ts 138	[0.3256	0.1477	0.0467	0.1887	0.0841	0.0156	0.1916]
  table:put issue-salience-ts 162	[0.319	0.1885	0.0469	0.2032	0.0834	0.0244	0.1346]
  table:put issue-salience-ts 189	[0.2858	0.1865	0.0713	0.1892	0.1008	0.0166	0.1498]
  table:put issue-salience-ts 190	[0.2268	0.2016	0.0774	0.1875	0.1367	0.0051	0.1649]
  table:put issue-salience-ts 214	[0.1882	0.285	0.0612	0.1617	0.1032	0.0187	0.182]
  table:put issue-salience-ts 233	[0.2009	0.2837	0.0659	0.1571	0.1505	0.0187	0.1232]

  set current-issue-salience table:get issue-salience-ts 0
  set issue-salience-changeover table:keys issue-salience-ts
end

to update-issue-salience
  if (member? ticks issue-salience-changeover) [
    set current-issue-salience table:get issue-salience-ts ticks
  ]
end

to init-voter-mip-map
  ;; represented mips are 10000 (economy), 11000 (welfare state), 12000 (budget), 14000 (security), 19000 (society), 20000 (environment), 22000 (immigration)
  ;; in this order: ["economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order" "left-right"]
  set voter-mip-map table:make
  table:put voter-mip-map 10000 0  ;; "economy"
  table:put voter-mip-map 11000 1  ;; "welfare state"
  table:put voter-mip-map 12000 2  ;; "budget"
  table:put voter-mip-map 13000 -1 ;; "education and culture" ## -1: not represented in model
  table:put voter-mip-map 14000 6  ;; "security"
  table:put voter-mip-map 15000 -1 ;; "army"
  table:put voter-mip-map 16000 -1 ;; "foreign policy"
  table:put voter-mip-map 17000 -1 ;; "europe"
  table:put voter-mip-map 18000 -1 ;; "infrastructure"
  table:put voter-mip-map 19000 5  ;; "society"
  table:put voter-mip-map 20000 4  ;; "environmental protection"
  table:put voter-mip-map 21000 -1 ;; "institutional reform"
  table:put voter-mip-map 22000 3  ;; "immigration"
  table:put voter-mip-map 23000 -1 ;; "government formation"
  table:put voter-mip-map 24000 -1 ;; "ideology"
  table:put voter-mip-map 25000 -1 ;; "politics"
  table:put voter-mip-map 77777 -2 ;; "multiple issues"   ## -2: at least two issues
  table:put voter-mip-map 99999 -3 ;; "not classifiable"  ## -3: interpreted as none
end

to init-party-mip-map
  set party-mip-map table:make
  table:put party-mip-map "state intervention"	0
  table:put party-mip-map "redistribution"	1
  table:put party-mip-map "public services vs taxes"	2
  table:put party-mip-map "immigration"	3
  table:put party-mip-map "environment"	4
  table:put party-mip-map "deregulation"	0 ;; -1          ;; for now, we shall replace deregulation with "economy" (even though it's represented as position on state intervention; this concerns parties ÖVP, BZÖ, NEOS, Team Stronach)
  table:put party-mip-map "corruption"	-1
  table:put party-mip-map "anti-elite rhetoric"	-1
  table:put party-mip-map "urban vs rural"	-1
  table:put party-mip-map "nationalism"	6 ;;-1              ;; for now, we shall replace nationalism with law and order (this concerns parties FPÖ and BZÖ)
  table:put party-mip-map "social lifestyle"	5
  table:put party-mip-map "tie: deregulation and nationalism"	6 ;;-2
  table:put party-mip-map "civil liberties vs. law and order"	6
end

to init-voters
  ;; read in voter data from file and create voter agents
  file-close-all
  file-open voter-data
  let row csv:from-row file-read-line ;; discard header
  while [not file-at-end?] [

    set row csv:from-row file-read-line

    create-voters 1 [
      set id first row
      set gender item 1 row
      set age item 2 row
      set education-level item 3 row
      if (education-level = "") [ set education-level 0 ] ;; account for missing values
      set education-level convert-to-ed-range education-level
      set residential-area item 4 row
      if (residential-area = "") [ set residential-area 0 ]
      set income-situation item 5 row
      if (income-situation = "") [ set income-situation 0 ]
      set political-interest item 7 row
      if (political-interest = "") [ set political-interest 2.5 ]  ;; #### instead of 0 set it to middling

      ;; ### initialise affective involvement from political interest
      ;; (a) reverse it (so that instead of 1 meaning high, 4 will mean high)
      set aff-level 5 - political-interest
      ;; (b) add some noise, otherwise everyone with high political interest will not interact at all
      set aff-level aff-level + add-some-noise
      ;; (c) scale it to [0,1]
      ;set aff-level (aff-level - 1) / 3
      set aff-level aff-level / 5

      ;; read in most important issues from columns 9 (mip), 10 (mip second wave), 11 (mip-2)
      let mips []
      foreach [9 10 11] [ i ->
        set mips lput (convert-voter-mip item i row) mips
      ]
      ;; read-in parties best able to handle those issues from columns 12 (pmip), 13 (second wave), 14 (pmip-2)
      let pmips []
      foreach [12 13 14] [ i ->
        set pmips lput (convert-voter-party-id item i row) pmips
      ]
      ;; handle problems:
      ;; -- a mip of -1 means the voter issue is not represented in the model --> either do not use or assign a different issue for which the chosen pmip would be right
      ;; -- a mip of -2 means the voter had multiple issues --> assign two mips from the allowed list, use respective pmip for both (if set)
      ;; -- a mip of -3 means the voter issue was not classifiable or is missing --> do not enter into my-issues
      set my-issues []
      set my-saliences n-values length model-issues [0]
      let opmips handle-voter-mips mips pmips

      ;; assign opinions from issues and parties
      set op-history []
      assign-opinions opmips

      set closest-party convert-voter-party-id item 16 row
      set degree-of-closeness item 17 row
      if (degree-of-closeness = "") [ set degree-of-closeness 0 ]

      ;; read in propensities to vote for the different parties
      ;; ### BUGGER: did not adhere to different model party ids!!
      ;; ### model party ids: SPO (1), ÖVP (2), FPÖ (3), Grüne (4), BYÖ (5), NEOS (6), TS (7) --> Grüne and BZÖ need to be swapped!!!
      let temp [0]
      let v item 18 row  ;; propensity to vote SPÖ (1)
      if (v = "") [ set v 0 ]
      set temp lput v temp
      set v item 19 row ;; propensity to vote ÖVP (2)
      if (v = "") [ set v 0 ]
      set temp lput v temp
      set v item 20 row ;; propensity to vote FPÖ (3)
      if (v = "") [ set v 0 ]
      set temp lput v temp
      set v item 22 row ;; propensity to vote Grüne (5) --> 4 in model
      if (v = "") [ set v 0 ]
      set temp lput v temp
       set v item 21 row ;; propensity to vote BZÖ (4) --> 5 in model
      if (v = "") [ set v 0 ]
      set temp lput v temp
     set temp lput 0 temp  ;; NEOS (6) is missing, people were not asked about it
      set v item 23 row ;; propensity to vote Team Stronach (7)
      if (v = "") [ set v 0 ]
      set temp lput v temp
      set pp temp

      set voted-party convert-voter-party-id item 24 row
      set prob-vote item 25 row
      if prob-vote = "" [ set prob-vote -1 ]
      set mvf-party convert-voter-party-id ifelse-value (prob-vote > 4) [item 27 row][item 28 row]

      ;; read in positions on model issues "economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order" "left-right"
      ;; these are variables "w1_q26_1" "w1_q26_2" "w1_q26_3" (add and reverse w1_q26_11/12 -> "a_immigration_index") "w1_q26_9" "w1_q26_6" "w1_q26_7" "w1_q12"
      ;; which are found in columns 33 34 35 149 41 38 39 15
      ;; -- note that economy and law and order need to be reversed to match the scale of the associated CHES variables
      set temp []
      set v item 33 row  ;; state intervention in economy
      if (v = "") [ set v 3 ]  ;; #### for every issue: if question not answered assign answer 3 = "neither agree nor disagree" instead of 0
      set v reverse-scale v
      set temp lput v temp
      set v item 34 row  ;; balance income difference
      if (v = "") [ set v 3 ]
      set temp lput v temp
      set v item 35 row  ;; spend vs. tax (in this case: fight unemployment)
      if (v = "") [ set v 3 ]
      set temp lput v temp
      set v item 149 row  ;; immigration policy
      if (v = "") [ set v 3 ]
      set temp lput v temp
      set v item 41 row  ;; environmental protection
      if (v = "") [ set v 3 ]
      set temp lput v temp
      set v item 38 row  ;; same rights for same-sex unions
      if (v = "") [ set v 3 ]
      set temp lput v temp
      set v item 39 row  ;; punish criminals severely
      if (v = "") [ set v 3 ]
      set v reverse-scale v
      set temp lput v temp
      set v item 15 row  ;; left-right self placement ### needs to be converted from 0-10 scale to 1-5 scale to be able to use it in visualisation (and to match CHES)
      if (v = "") [ set v 5 ] ;; assign centre position if no answer
      set v scale-down v
      set temp lput v temp
      set my-positions temp

      set current-p closest-party
      if (current-p = 0) [ set current-p mvf-party ]
      set vote-history (list (list current-p 0))

      ;; assign decision-making strategy according to the "distribution" set by the model parameters
      if (assign-from-data?) [
        ;; use info in data file for assignment in addition to the given "distribution"
        set my-strategy read-from-string item 150 row ;; read in list of possible strategies from file
      ]
      ;; the actual assignment will have to be done later, when all voters have been created
      ;; --> new procedure assign-strategies
;      ifelse (empty? strategy-probs) [
;        set my-strategy item 150 row  ;; read in from data file
;      ][
;        set my-strategy sample-empirical-dist strategy-probs (range 1 6)
;      ]

      set pos-history []
      set talked-about n-values (length model-issues - 1) [0]
      set talked-to []    ;; history of whom I talked to
      set shape "person"
      set size age * 0.025
      set color item current-p party-colours
      ;; translate all positions
      translate-positions my-positions true
      ;; adopt coordinates to display
      update-coords
      ;update-size

      ;; be attracted by closest party depending on degree of closeness
      let acp find-party closest-party
      if (acp != nobody) [
        face acp
        fd 4 - degree-of-closeness
      ]
    ]
  ]
  file-close
end

to assign-strategies
  ;; for assignment of voter strategies, keep track of how many of each we have assigned already (if using info from file)
  ;; so we can make sure we get the given proportions
  let str-bins [0 0 0 0 0 0]  ;; one counter per strategy, first item only there to make sure I can use the strategy id as an index
  let n count voters
  let str-goals map [i -> round (count voters * i)] strategy-probs  ;; this might end up with 1 or 2 too many
  set str-goals fput 0 str-goals

;  let singles voters with [my-strategy != 0 and length my-strategy = 1]
;  show (word "voters with just one strategy: " count singles)
;  show (word "distribution: " map [i -> count singles with [first my-strategy = i]] [1 2 3 4 5])
;  show (word "str-goals: " str-goals)

  ask voters with [my-strategy != 0 and empty? my-strategy] [
    ;; replace empty list with 0
    set my-strategy 0
  ]
  ask voters with [my-strategy != 0 ] [
    ifelse (length my-strategy = 1) [
      ;; voter has only one possible strategy -- assign it
      set my-strategy first my-strategy
      set str-bins replace-item my-strategy str-bins (item my-strategy str-bins + 1)
    ][
      ;; voter has more than one possible strategy
      ifelse (item 2 str-bins < item 2 str-goals and member? 2 my-strategy) [
        ;; assign strategy 2 as it trumps everything
        set my-strategy 2
        set str-bins replace-item my-strategy str-bins (item my-strategy str-bins + 1)
      ][
        ;; assign a random strategy but make sure we don't overrun the goals
        let str-p my-strategy
        while [not empty? str-p] [
          ;; pick a card, any card...
          let s one-of str-p
          set str-p remove s str-p
          if (item s str-bins < item s str-goals) [
            ;; take it
            set my-strategy s
            set str-bins replace-item my-strategy str-bins (item my-strategy str-bins + 1)
            set str-p []
          ]
        ]
        ;; check if we found one
        if (empty? str-p and is-list? my-strategy) [
          ;; we didn't find one
          set my-strategy 0
        ]
      ]
    ]
  ]
  ;; assign strategies to voters who don't have one yet
;  show (word "str-goals: " str-goals)
;  show (word "str-bins : " str-bins)
  ;; problem: there is an imbalance-- we overran the goals on some items (2 and 5) and I don't know why ###
  set str-bins balance-bins str-bins str-goals
;  show (word "str-bins : " str-bins " after balancing")
  foreach [1 2 3 4 5] [i ->
    ask n-of (item i str-bins) voters with [my-strategy = 0] [
      set my-strategy i
    ]
  ]
end

to-report balance-bins [bins goals]
  let diff (map - goals bins)
  ;; if there are any negative values, have to subtract them from the positive ones
  let negs filter [i -> i < 0] diff
  ;let p-negs map [i -> position i diff] negs   ;; ##### in the very rare case that (some of )the negative numbers in diff are identical (e.g. [0 13 -12 165 44 -12]), position will only find the FIRST occurrence and then balancing doesn't work
  let p-negs map [i -> all-positions-of i diff] negs
  set p-negs flatten-all-u p-negs
  foreach p-negs [i ->
    let m max diff
    let p-m position m diff
    set diff replace-item p-m diff (m + item i diff)
    set diff replace-item i diff 0
  ]
  ;; now check if the sum of diff equals number of voters without strategy yet
  let dv (sum diff - count voters with [my-strategy = 0])
  if (dv != 0) [
    ;; adjust again
    let m max diff
    let p-m position m diff
    set diff replace-item p-m diff (m - dv)
  ]
  report diff
end

to-report handle-voter-mips [mlist plist]
  ;; mlist has three entries: m1 first wave, m1 second wave, m2 first wave
  ;; with the following possible exceptions:
  ;; -1 issue not represented in the model --> we pick 1 issue from the modelled list (or use m1 second wave instead)
  ;; -2 multiple issues (original: 77777) --> we pick 2 issues from the modelled list (or use m1 second wave instead)
  ;; -3 answer missing or not classifiable --> we ignore it (or use m1 second wave instead)

  ;; -- so first we check if we need to use the second entry
  let milist (list last mlist) ;; we definitely use the last entry: m2
  let pilist (list last plist)
  ifelse (first mlist < 0 and first but-first mlist >= 0) [
    ;; replace m1 first wave with m1 second wave
    set milist fput first but-first mlist milist
    set pilist fput first but-first plist pilist
  ][
    ;; we take m1 first wave
    set milist fput first mlist milist
    set pilist fput first plist pilist
  ]
  ;; now handle the exceptions
  set my-issues []
  let pmlist []
  foreach [0 1] [ i ->
    let mi item i milist
    (ifelse
      mi = -3 [
        ;; ignore it
      ]
      mi = -2 [
        ;; pick two issues according to the distribution defined in voter-mip-probs
        repeat 2 [
          ;; pick one issue
          let m get-a-mip
          if (not member? m my-issues) [   ;; avoid duplicates
            set my-issues lput m my-issues
            set pmlist lput item i pilist pmlist
          ]
        ]
      ]
      mi = -1 [
        ;; pick one issue
        let m get-a-mip
        if (not member? m my-issues) [
          set my-issues lput m my-issues
          set pmlist lput item i pilist pmlist
        ]
      ]
      ;; else
      [
        ;; take values across (unless duplicates!)
        if (not member? mi my-issues) [
          set my-issues lput mi my-issues
          set pmlist lput item i pilist pmlist
        ]
      ]
    )
  ]
  ;; assign importances (if there are any issues)
  let weights []
  foreach n-values length my-issues [i -> i] [ i ->
    set weights lput generate-a-weight weights
  ]
  if (not empty? weights) [ set weights adjust-weights weights ]
  foreach n-values length weights [i -> i] [ i ->
    set my-saliences replace-item (item i my-issues) my-saliences (item i weights)
  ]

  report pmlist
end

to-report generate-a-weight
  ;; precision (min (list 0.8 max (list 0.2 random-normal 0.5 0.1))) 3
  report ceiling (precision (min (list 0.8 max (list 0.2 random-normal 0.4 0.2))) 2 * 100)
end

to-report adjust-weights [wlist]
  while [sum wlist > 100] [
;    ;; pick a random entry and reduce it by something between 1 and 4
;    let i random length wlist
    ;; pick the largest entry and reduce it by something between 1 and 4  ### this should help to avoid negative weights
    let i position (max wlist) wlist
    set wlist replace-item i wlist (item i wlist - (1 + random 4))
  ]
  while [sum wlist < 100] [
    ;; pick a random entry and augment it by something between 1 and 2
    let i random length wlist
    set wlist replace-item i wlist (item i wlist + (1 + random 2))
  ]
  ;; make sure everything adds up to 1
  ;; pick a random entry and remove what's too much
  if (sum wlist > 100) [
    let i random length wlist
    set wlist replace-item i wlist (item i wlist - (sum wlist - 100))
  ]

;  while [sum wlist > 1] [
;    ;; pick a random entry and reduce it by something between 0.001 and 0.05
;    let i random length wlist
;    set wlist replace-item i wlist (item i wlist - (0.001 + precision (random-float 0.049) 3))
;  ]
;  while [sum wlist < 1] [
;    ;; pick a random entry and augment it by something between 0.001 and 0.04
;    let i random length wlist
;    set wlist replace-item i wlist (item i wlist + (0.001 + precision (random-float 0.039) 3))
;  ]
;  ;; make sure everything adds up to 1
;  ;; pick a random entry and add missing bits
;  if (sum wlist > 1) [
;    let i random length wlist
;    set wlist replace-item i wlist (item i wlist - precision (1 - sum wlist) 3)
;  ]
  report sort-by > wlist
end


to assign-opinions [plist]
  ;; plist is the list of parties I think are best for my-issues
  ;; opinions is a 2d array with outer index = issue, inner index = party, element = measure of success (between -1 0 1)
  set my-opinions array:from-list range (length model-issues - 1) ;; ignore left-right position
  foreach range (length model-issues - 1) [ i ->
    array:set my-opinions i array:from-list n-values length party-names [0]
  ]
  ;; assign initial opinions
  foreach range (length my-issues) [ i ->
    add-opinion (item i my-issues) (item i plist) 1
;    let ilist array:item my-opinions (item i my-issues)
;    array:set ilist (item i plist) 1  ;; no party is index 0 in this array
  ]

  ;; an opinion is a list [îssue party measure-of-success], with measure-of-success between -1 0 1   (for now)
  ;; using 0 if no party
  ;; using 1 if a party
;  set my-opinions factbase:create ["issue" "party" "measure" "tick"]
;  foreach n-values length my-issues [j -> j] [ i ->
;    factbase:assert my-opinions (list item i my-issues item i plist ifelse-value (item i plist = 0)[0][1] -1)
;  ]
end

to assign-importance [mindex ilist]
  ;; most important issue (mindex = 1) gets slightly higher importance
  let imp 0
  ifelse (mindex = 1) [
    set imp min (list 0.8 max (list 0.4 random-normal 0.5 0.1))
  ][
    set imp min (list 0.49 max (list 0.2 random-normal 0.35 0.1))
    ;; check it's not too high
    ifelse (imp + sum my-saliences >= 1) [
      set imp 1 - sum my-saliences
    ][
      ;; pick a random issue not yet taken and give it the "rest" of the weight??? #####
    ]
  ]
  ;; insert into my-saliences at the right place(s)
  ifelse (last ilist >= 0) [
    ;; there are two issues (77777 originally) --> divide imp / 2 and put in both places
    set my-saliences replace-item (first ilist) my-saliences (imp / 2)
    set my-saliences replace-item (last ilist) my-saliences (imp / 2)
  ][
    set my-saliences replace-item (first ilist) my-saliences imp
  ]
end

to-report convert-voter-mip [iid]
  ;; convert read-in most important issue to model-internal issue
  if (iid = "") [ report -3 ]
  report table:get voter-mip-map iid
end

to-report convert-voter-party-id [p]
  ;; convert read-in party id to model-internal party id
  ;; this will involve some loss of information as we only recognise 7 parties (from CHES), not the 12 options from AUTNES (which include "no party")
  if (p = "") [ set p 0 ]
  report item p autnes-party-id-map
end

to-report convert-to-ed-range [e-level]
  let education-bounds [0 5 9 14 15] ;; upper bounds for NULL, low, medium, high, other
;;  let education-levels ["NULL" "low" "medium" "high" "other"]
  let i 0
  while [e-level > item i education-bounds and i < length education-bounds] [
    set i i + 1
  ]
;;  report item i education-levels
  report i
end

to-report reverse-scale [v]
   let value 6 - v
  report ifelse-value (value = 6) [0][value]
end

to-report scale-down [v]
  if (v <= 1) [ report 1 ]
  if (v <= 3) [ report 2 ]
  if (v <= 6) [ report 3 ]
  if (v <= 8) [ report 4 ]
  report 5
end

to-report add-some-noise
  let n random-normal 0 0.4
  ;; cut off >= 1 and <= 1 so that we don't end up in a different category of answer
;  if (n < -1) [report n + 1]
;  if (n > 1) [report n - 1]
  while [n < -0.5 or n > 0.5] [set n random-normal 0 0.4]
  report n
end

to-report find-party [p-id]
  report one-of parties with [id = p-id]
end

to init-parties
  ;; read in strategies
  let pstr read-from-string party-strategies ;; one entry per party
  set pstr fput 0 pstr ;; add 0 for "NULL" party
  ;; read party data from file
  ;; file has these columns: party_name,party_id,econ_interven,redistribution,spendvtax,immigrate_policy,environment,sociallifestyle,civlib_laworder,
  ;;                         lrecon,multiculturalism,nationalism,mip_one,mip_two,mip_three,vote_share_2013,change
  file-close-all
  file-open party-data
  let row csv:from-row file-read-line ;; discard header
  while [not file-at-end?] [
    set row csv:from-row file-read-line
    create-parties 1 [
      set id position (item 1 row) ches-party-id-map
      set name item id party-names
      ;; read in positions on issues
      let temp []
      foreach n-values 8 [i -> 2 + i] [ x ->
        set temp lput (item x row) temp
      ]
      set our-positions temp
      ;; read in most important issues (columns 12-14)
      set temp[]
      foreach [12 13 14] [ x ->
        set temp lput (convert-party-mip item x row) temp
      ]
      handle-party-mips temp
      ;; read in 2013 election results and change to previous election (columns 15-16)
      set vote-share (list item 15 row)
      set vs-change item 16 row
      set vs-aspiration-level ifelse-value (vs-change < 0) [first vote-share - vs-change][first vote-share]  ;; if change is negative, party wants losses back

      set our-strategy item id pstr
      ;; h-dims and h-directions can only be set after voters have been created
      set pos-history []

      set shape "wheel"
      set size 3
      set color item id party-colours
      ;; translate all positions
      translate-positions our-positions false
      ;; adopt coordinates to display
      update-coords

      ;; set ideal positions and phi
      set phi 0
      set ideal-pos positions

      ;; set government participation
      set gov? false
    ]
  ]
  file-close
  ;; set SPÖ and ÖVP as government parties (quick and dirty ###)
  ask party 1 [set gov? true]
  ask party 2 [set gov? true]
end

to-report convert-party-mip [mstring]
  ;; convert read-in most important issue to model-internal issue
  if (mstring = "") [ report -3 ]
  report table:get party-mip-map mstring
end

to handle-party-mips [mlist]
  ;; -1 means the issue is not represented in the model --> for now we just ignore it and remove it from the list
  ;; -2 and -3 do not occur as we already solved the one tie  and there are no missing answers
  set our-issues []
  foreach mlist [ m ->
    if (m >= 0 and not member? m our-issues) [ set our-issues lput m our-issues ]  ;; make sure there are no duplicates
  ]
  ;; assign importances:
  ;; if there are 3 issues, we use the weights CHES assigns (10/16, 5/16, 1/16)
  ;; if there are 2 issues, we use slightly adjusted weights 0.65, 0.35
  ;; if there is just 1 issue, weight is 1
  let weights [[1] [0.65 0.35] [0.625 0.3125 0.0625]]
  let w-index length our-issues - 1
  set our-saliences n-values (length model-issues - 1) [0]
  foreach n-values length our-issues [i -> i] [ i ->
    set our-saliences replace-item (item i our-issues) our-saliences (item i (item w-index weights))
  ]
end

to init-h-directions
  set h-heading []
  ;; right-wing parties tend to move further right on issues
  ;; left-wing parties tend to move further left, centre parties pick randomly
  ;; right-wing: position on left-right is >= 3.7, left-wing: left-right position is <= 2.3, centre in the middle
  ;; only set directions for the parties chosen hunter dimensions, leave the other issues 0
  let h-directions n-values (length positions - 1) [0]
  (ifelse
    last positions >= 3.7 [
      foreach h-dims [ i ->
        set h-directions replace-item i h-directions 1
      ]
    ]
    last positions <= 2.3 [
      foreach h-dims [ i ->
        set h-directions replace-item i h-directions -1
      ]
    ]
    [
      foreach h-dims [ i ->
          set h-directions replace-item i h-directions (-1 + random 3) ;; -1, 0 or 1
      ]
    ]
  )
  ;; now use heading to assign direction
  let vector map [x -> item x h-directions] h-dims
  set h-dist max-p-move ;;0.5
  (ifelse
    vector = [0 1] [
      ;; move up = 0° in Netlogo
      set heading 0
    ]
    vector = [1 0] [
      ;; move right = 90°
      set heading 90
    ]
    vector = [0 -1] [
      set heading 180
    ]
    vector = [-1 0] [
      set heading 270
    ]
    vector = [1 1] [
      set heading 45
    ]
    vector = [1 -1] [
      set heading 135
    ]
    vector = [-1 -1] [
      set heading 225
    ]
    vector = [-1 1] [
      set heading 315
    ]
    [
      ;; else: don't move
      set heading 0
      set h-dist 0
    ]
  )
end

to init-h-dims
  ;; choose our two most important issues, or if we don't have two, our most important issue and the most important issue of the voters
  set h-dims our-issues
  if (length our-issues > 2) [
    set h-dims but-last h-dims
  ]
  if (length our-issues < 2) [
    ;; use most prominent mip of our supporters
    let pid id
    let sup-mip map [x -> occurrences x [first my-issues] of voters with [not empty? my-issues and current-p = id] ] range 7
    let sup-dim most-prominent sup-mip first our-issues
    set h-dims lput sup-dim h-dims
  ]
end

to-report most-prominent [ilist not-this]
  let mp position (max ilist) ilist
  while [mp = not-this and sum ilist > 0] [
    set ilist replace-item mp ilist 0
    set mp position (max ilist) ilist
  ]
  report mp
end

to go
  ;; try to avoid RUNTIME ERROR: The tick counter has not been started yet. Use RESET-TICKS when using BehaviourSpace on Linux
  ;carefully [let t ticks][reset-ticks]  ;; This might have happened because the voter data file was missing so setup didn't go through completely = reset-ticks wasn't called

  ;; any party events happen
  handle-party-events

  ;; parties update their vote share
  ask parties [
    set vote-share lput proportion-of-party id vote-share
    set vs-change last vote-share - (last but-last vote-share)
  ]

  ;; voters read the media and are influenced by this several times per tick
  ;; ## as a proxy, we are changing the probabilities for issue saliences taken from EuroBarometer
  update-issue-salience
;  repeat 2 + random 5 [
;    ask voters [
;      ;; get a media 'message' and think about it
;      receive-media-message
;    ]
;  ]

  ;; voters talk to other voters and influence each other several times per tick
  repeat discussion-freq [
    ask voters [
      ;; influence friends
      ;influence-friend-fixed-network
      influence-friend-random
    ]
  ]
  if probability (discussion-freq - floor discussion-freq) [
    ask voters [
      ;; influence friends
      ;influence-friend-fixed-network
      influence-friend-random
    ]
  ]
  ;; voters decide who they'd vote for at the moment according to their voting strategy
  ask voters [
    make-party-decision
  ]

  ;; parties decide to adapt their position according to their strategy
  ask parties [
    apply-strategy
  ]

  ;; update positions of voters and parties
  change-dimensions

  ;; evolve social network
  if (dynamic-network?) [
    evolve-network
  ]

  ;; update distance measures
  set d-measures compute-distance-measures
  if ticks >= max-tick [stats stop]

  tick
end

;; -------------- statistics done at end or when "do stats" button pressed -----------------------

to stats
  set av-positions-voters av-list [positions] of voters
  set av-positions-parties av-list [positions] of parties
  set av-dist-cv-voters mean map [? -> (pos-dist ? av-positions-voters)] [positions] of voters
  set av-dist-cv-parties mean map [? -> (pos-dist ? av-positions-voters)] [positions] of parties
end

to-report av-list [lol]
  let len length lol
  if len = 1 [report first lol]
  let sumol first lol
  foreach but-first lol [nl ->
    set sumol (map +  sumol nl)
  ]
  report map [? -> ? / len] sumol
end

to-report pos-dist [p1 p2]
  let subps (map - p1 p2)
  let absub map [? -> ? * ?] subps
  let sm sum absub
  report sqrt sm
end

to-report pv [th]
  print th
  report th
end

;; ------------- party strategies ----------------------------------------------------------------

to apply-strategy
  (ifelse
    our-strategy = 0 [
      ;; party is a sticker = does not change its positions
      ;; do nothing
    ]
    our-strategy = 1 [
      ;; party is a satisficer
      p-satisficer
    ]
    our-strategy = 2 [
      ;; party is an aggregator
      p-aggregator-new
    ]
    our-strategy = 3 [
      ;; party is a hunter
      p-hunter
    ]
  )
end

to p-satisficer
  ;; check if we need to move at all: is current vote-share over threshold of 25% away from our aspiration?
  if (last vote-share < vs-aspiration-level - 0.25 * vs-aspiration-level) [
    ;; move towards average position of supporters, aka be an aggregator
    p-aggregator
  ]
end

to p-aggregator-pure
  ;; move towards average position of supporters on every dimension
  ;; if there aren't any supporters, move to average position of everyone
  set pos-history lput positions pos-history
  let pid id
  let supporters voters with [current-p = pid]
  if not any? supporters [ set supporters voters ]
  let pidx range (length positions - 1)
  let averages map [x -> mean [item x positions] of supporters] pidx  ;; calculate average positions of supporters on all issues (except left-right)
  let diffs map [x -> item x averages - item x positions] pidx        ;; calculate difference to our positions
  let directions map [x -> ifelse-value item x diffs >= 0 [1][-1]] pidx  ;; direction is sign of difference (+1 or -1)
  set diffs map [x -> min (list abs x max-p-move)] diffs  ;; calculate absolute distance to move with maximum shift of 0.5 per step
  let new-positions map [x -> item x positions + (item x directions) * (item x diffs)] pidx
  ;; add unchanged left-right position
  set new-positions lput (last positions) new-positions
  set positions new-positions
end

to p-aggregator
    ;; ### don't move on EVERY dimension, just the ones we find most important
  set pos-history lput positions pos-history
  let pid id
  let supporters voters with [current-p = pid]
  if (not any? supporters or last vote-share < 11) [ set supporters voters ]  ;; ### or if vote share is lower than some threshold
  let pidx range length our-issues
  let averages map [x -> mean [item x positions] of supporters] our-issues  ;; calculate average positions of supporters on our issues
  let diffs map [x -> item x averages - item (item x our-issues) positions] pidx  ;; calculate difference to our positions
  let directions map [x -> ifelse-value item x diffs >= 0 [1][-1]] pidx  ;; direction is sign of difference
  set diffs map [x -> min (list abs x max-p-move)] diffs  ;; calculate absolute distance to move with maximum shift of max-p-move per step
;  show (word "pidx: " pidx " averages: " averages " diffs: " diffs " directions: " directions)
;  show (word "positions: " positions)
  ;; change positions
  foreach pidx [ i ->
    set positions replace-item (item i our-issues) positions (item (item i our-issues) positions + (item i directions) * (item i diffs))
  ]
;  show (word "positions now: " positions)
end

to  p-aggregator-new
  ;; ### don't move on EVERY dimension, just the ones we find most important
  ;; use phi and ideal points
  set pos-history lput positions pos-history
  let pid id
  let supporters voters with [current-p = pid]
  if (not any? supporters or last vote-share < 11) [ set supporters voters ]  ;; ### or if vote share is lower than some threshold
  let pidx range length our-issues
  let averages map [x -> mean [item x positions] of supporters] our-issues  ;; calculate average positions of supporters on our issues
  let targets map [x -> phi * item x ideal-pos] our-issues  ;; first part: phi * ideal positions
  set averages map [x -> (1 - phi) * x] averages            ;; second part: (1 - phi) * supporters' positions
  set targets (map + averages targets)                      ;; combine them
  let diffs map [x -> item x targets - item (item x our-issues) positions] pidx  ;; calculate difference FROM TARGETS to our positions
  let directions map [x -> ifelse-value item x diffs >= 0 [1][-1]] pidx  ;; direction is sign of difference
  set diffs map [x -> min (list abs x max-p-move)] diffs  ;; calculate absolute distance to move with maximum shift of max-p-move per step
;  show (word "pidx: " pidx " averages: " averages " diffs: " diffs " directions: " directions)
;  show (word "positions: " positions)
  ;; change positions
  foreach pidx [ i ->
    set positions replace-item (item i our-issues) positions (item (item i our-issues) positions + (item i directions) * (item i diffs))
  ]
;  show (word "positions now: " positions)
end

to p-hunter
  ;; continue shifting in current direction if previous move was successful; otherwise change direction
  ;; we shall only consider the two most important issues for the party
  set pos-history lput positions pos-history
  if (vs-change < 0) [
    ;; not successful --> change direction
    set h-heading lput heading h-heading
    set heading heading - 180 ;; turn around
    set heading heading - 90 + random 180 ;; choose randomly in 180° arc we are now facing
  ]

  set hidden? true
  let my-xy (list xcor ycor) ;; remember my position on screen
  setxy (item (first h-dims) positions) (item (last h-dims) positions)
  fd h-dist
  ;; retrieve new positions
  set positions replace-item (first h-dims) positions xcor
  set positions replace-item (last h-dims) positions ycor
  ;; restore vis (if displayed issues are different from dimensions we just moved on)
  if (first h-dims != position x-issue model-issues) [
    set xcor first my-xy
  ]
  if (last h-dims != position y-issue model-issues) [
    set ycor last my-xy
  ]
  set hidden? false
end

;; ------------- voters being influenced by the media ------------------------------------------

to receive-media-message
end

;; ------------- voters influencing each other --------------------------------------------------

;; instead of pairing random agents, we are using the social network
;; also change test if interaction happens: combine it for both agents, instead of having each of them check separately
;; -- it doesn't make much sense that one of them is ready for interaction and changes their position whereas the other
;;    one is not ready and doesn't change (but obviously still talked to the other guy somehow)
;; -- now they are both influenced by the one probability (random-float 1 < voter-adapt-prob), so question is should that be
;;    separated out? First test if they interact (if both think their distance is acceptable), then check for each of them
;;    separately if the interaction leads to any change in position?? ## Have decided no, that's not how it's done in opinion dynamics
to influence-friend-fixed-network
  ;; opinion dynamics style: talk to randomly picked people but only adapt position if not too different (distance < threshold)
  ;; let the threshold be determined by a voter's "affective involvement" so that people with a high political involvment change their opinions less
  ;;  (see Schweighofer et al. 2020)
  ;; -- affective involvement e is constant over time and is assigned from a normal distribution in [0,1] with mean mu_e and sd sigma_e
  ;; -- we shall use the political interest variable for this; it's constant over time and ranges between [1,4] with 1 meaning high and 4 meaning none
  ;;    so we need to (a) reverse it and (b) scale it; will do so while creating the voters adding new attribute aff-level
  ;; -- one problem: e is in [0,1], so epsilon = 1 - e is also in [0,1], which is fine for opinion dynamics models with opinions in [-1,1]
  ;;    I have opinions originally in [1,5], with noise added and translated to positions in [-33,33]
  ;;    so we'll have to normalise the distance to [0,1] (by dividing by 66 = max distance in one dimension) before checking
  ;;
  ;let epsilon 1 - aff-level
  ;; step 1: pick a random friend from my network
  let friend one-of link-neighbors
  if (friend = nobody) [ stop ]
  ;; step 2: pick a topic determined by current issue salience
  let i sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
  ;; step 3: check if we actually interact, i.e. our position on the issue is not too far apart
  let dist plain-distance-in-dims-to friend (list i)  ;; guess we could also use weighted distance here #####
  ;set dist dist / 66  ;; normalise dist
  if (accept-interaction? dist and [accept-interaction? dist] of friend and (random-float 1 < voter-adapt-prob)) [ ;;(dist < epsilon) [
    set inf-count inf-count + 1
    ;; we both move; question is how?
    ;; only if we agree on the majority of other issues, am I willing to move towards you; otherwise I will move away
    let signs sort-out-directions i friend
    ;; ### record outcome of interaction in link ----------
    ;; ### only need to do this once for the both of us, since it's an undirected link and the outcome is the same for both:
    ;; ### -1: disagreement, 1: agreement
    let our-link link who [who] of friend
    ask our-link [ set outcomes lput last signs outcomes ]
    set signs but-last signs
    ;; ### -------------------------------------------------
    ;; first signs is me, last signs is my friend
    ;if (random-float 1 < voter-adapt-prob) [
      adjust-position i friend (first signs)
      adjust-salience i
    ;]
    set talked-about replace-item i talked-about (item i talked-about + 1)
    update-talked-to friend
    ask friend [
      ;if (random-float 1 < voter-adapt-prob) [
        adjust-position i myself (last signs)
        adjust-salience i
      ;]
      set talked-about replace-item i talked-about (item i talked-about + 1)
      update-talked-to myself
    ]
  ]
  ;; we are now ignoring opinions
end

;;; instead of pairing random agents, we are using the social network
;to influence-friend-fixed-network-old
;  ;; opinion dynamics style: talk to randomly picked people but only adapt position if not too different (distance < threshold)
;  ;; let the threshold be determined by a voter's "affective involvement" so that people with a high political involvment change their opinions less
;  ;;  (see Schweighofer et al. 2020)
;  ;; -- affective involvement e is constant over time and is assigned from a normal distribution in [0,1] with mean mu_e and sd sigma_e
;  ;; -- we shall use the political interest variable for this; it's constant over time and ranges between [1,4] with 1 meaning high and 4 meaning none
;  ;;    so we need to (a) reverse it and (b) scale it; will do so while creating the voters adding new attribute aff-level
;  ;; -- one problem: e is in [0,1], so epsilon = 1 - e is also in [0,1], which is fine for opinion dynamics models with opinions in [-1,1]
;  ;;    I have opinions originally in [1,5], with noise added and translated to positions in [-33,33]
;  ;;    so we'll have to normalise the distance to [0,1] (by dividing by 66 = max distance in one dimension) before checking
;  ;;
;  ;let epsilon 1 - aff-level
;  ;; step 1: pick a random friend from my network
;  let friend one-of link-neighbors
;  if (friend = nobody) [ stop ]
;  ;; step 2: pick a topic determined by current issue salience
;  let i sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
;  ;; step 3: check if we actually interact, i.e. our position on the issue is not too far apart
;  let dist plain-distance-in-dims-to friend (list i)  ;; guess we could also use weighted distance here #####
;  ;set dist dist / 66  ;; normalise dist
;  if (accept-interaction? dist and (random-float 1 < voter-adapt-prob)) [ ;;(dist < epsilon) [
;    set inf-count inf-count + 1
;    ;; we both move; question is how?
;    ;; only if we agree on the majority of other issues, am I willing to move towards you; otherwise I will move away
;    let signs sort-out-directions i friend
;    ;; ### record outcome of interaction in link ----------
;    ;; ### only need to do this once for the both of us, since it's an undirected link and the outcome is the same for both:
;    ;; ### -1: disagreement, 1: agreement
;    let our-link link who [who] of friend
;    ask our-link [ set outcomes lput last signs outcomes ]
;    set signs but-last signs
;    ;; ### -------------------------------------------------
;    ;; first signs is me, last signs is my friend
;    adjust-position i friend (first signs)
;    adjust-salience i
;    set talked-about replace-item i talked-about (item i talked-about + 1)
;    update-talked-to friend
;    if [accept-interaction? dist and (random-float 1 < voter-adapt-prob)] of friend [
;      ask friend [
;        adjust-position i myself (last signs)
;        adjust-salience i
;        set talked-about replace-item i talked-about (item i talked-about + 1)
;        update-talked-to myself
;      ]
;    ]
;  ]
;  ;; we are now ignoring opinions
;end

;; also change test if interaction happens: combine it for both agents, instead of having each of them check separately
;; -- it doesn't make much sense that one of them is ready for interaction and changes their position whereas the other
;;    one is not ready and doesn't change (but obviously still talked to the other guy somehow)

to influence-friend-random
  ;; opinion dynamics style: talk to randomly picked people but only adapt position if not too different (distance < threshold)
  ;; let the threshold be determined by a voter's "affective involvement" so that people with a high political involvment change their opinions less
  ;;  (see Schweighofer et al. 2020)
  ;; -- affective involvement e is constant over time and is assigned from a normal distribution in [0,1] with mean mu_e and sd sigma_e
  ;; -- we shall use the political interest variable for this; it's constant over time and ranges between [1,4] with 1 meaning high and 4 meaning none
  ;;    so we need to (a) reverse it and (b) scale it; will do so while creating the voters adding new attribute aff-level
  ;; -- one problem: e is in [0,1], so epsilon = 1 - e is also in [0,1], which is fine for opinion dynamics models with opinions in [-1,1]
  ;;    I have opinions originally in [1,5], with noise added and translated to positions in [-33,33]
  ;;    so we'll have to normalise the distance to [0,1] (by dividing by 66 = max distance in one dimension) before checking
  ;;
  ;let epsilon 1 - aff-level
  ;; step 1: pick a random friend from my network
  let friend one-of link-neighbors
  if (friend = nobody) [ stop ]
  ;; step 2: pick a topic determined by current issue salience
  let i sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
  ;; step 3: check if we actually interact, i.e. our position on the issue is not too far apart
  let dist plain-distance-in-dims-to friend (list i)  ;; guess we could also use weighted distance here #####
  ;set dist dist / 66  ;; normalise dist
  if (accept-interaction? dist and (random-float 1 < voter-adapt-prob) and
       ( (symetric-infl? and [accept-interaction? dist] of friend) or (not symetric-infl?) ) )   [
;  if (accept-interaction? dist and ([accept-interaction? dist] of friend) and (random-float 1 < voter-adapt-prob)) [ ;; symetrical!!! BE
    set inf-count inf-count + 1
    ;; we both move; question is how?
    ;; only if we agree on the majority of other issues, am I willing to move towards you; otherwise I will move away
    let signs sort-out-directions i friend
    ;; ### record outcome of interaction in link ----------
    ;; ### only need to do this once for the both of us, since it's an undirected link and the outcome is the same for both:
    ;; ### -1: disagreement, 1: agreement
    let our-link link who [who] of friend
    ask our-link [ set outcomes lput last signs outcomes ]
    set signs but-last signs
    ;; ### -------------------------------------------------
    ;; first signs is me, last signs is my friend
    adjust-position i friend (first signs)
    adjust-salience i
    set talked-about replace-item i talked-about (item i talked-about + 1)
    update-talked-to friend
    ;; change aff level more if your aff-level is low
    set aff-level  (1 - ch-aff-fact) * aff-level
                  + ch-aff-fact      * ((aff-level) * aff-level +  (1 - aff-level) * [aff-level] of friend)
    if symetric-infl? [
      ask friend [
        adjust-position i myself (last signs)
        adjust-salience i
        set talked-about replace-item i talked-about (item i talked-about + 1)
        update-talked-to myself
        set aff-level (1 - ch-aff-fact) * aff-level + ch-aff-fact * [aff-level] of myself
      ]
    ]
  ]
  ;; we are now ignoring opinions
end

;to influence-friend-random-old
;  ;; opinion dynamics style: talk to randomly picked people but only adapt position if not too different (distance < threshold)
;  ;; let the threshold be determined by a voter's "affective involvement" so that people with a high political involvment change their opinions less
;  ;;  (see Schweighofer et al. 2020)
;  ;; -- affective involvement e is constant over time and is assigned from a normal distribution in [0,1] with mean mu_e and sd sigma_e
;  ;; -- we shall use the political interest variable for this; it's constant over time and ranges between [1,4] with 1 meaning high and 4 meaning none
;  ;;    so we need to (a) reverse it and (b) scale it; will do so while creating the voters adding new attribute aff-level
;  ;; -- one problem: e is in [0,1], so epsilon = 1 - e is also in [0,1], which is fine for opinion dynamics models with opinions in [-1,1]
;  ;;    I have opinions originally in [1,5], with noise added and translated to positions in [-33,33]
;  ;;    so we'll have to normalise the distance to [0,1] (by dividing by 66 = max distance in one dimension) before checking
;  ;;
;  ;let epsilon 1 - aff-level
;  ;; step 1: pick a random other voter
;  let friend one-of other voters
;  ;; step 2: pick a topic determined by current issue salience
;  let i sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
;  ;; step 3: check if we actually interact, i.e. our position on the issue is not too far apart
;  let dist plain-distance-in-dims-to friend (list i)  ;; guess we could also use weighted distance here #####
;  ;set dist dist / 66  ;; normalise dist
;  if (accept-interaction? dist and (random-float 1 < voter-adapt-prob)) [ ;;(dist < epsilon) [
;    set inf-count inf-count + 1
;    ;; we both move; question is how?
;    ;; only if we agree on the majority of other issues, am I willing to move towards you; otherwise I will move away
;    let signs sort-out-directions i friend
;    ;; first signs is me, last signs is my friend
;    adjust-position i friend (first signs)
;    adjust-salience i
;    set talked-about replace-item i talked-about (item i talked-about + 1)
;    update-talked-to friend
;    if [accept-interaction? dist and (random-float 1 < voter-adapt-prob)] of friend [
;      ask friend [
;        adjust-position i myself (last signs)
;        adjust-salience i
;        set talked-about replace-item i talked-about (item i talked-about + 1)
;        update-talked-to myself
;      ]
;    ]
;  ]
;  ;; we are now ignoring opinions
;end

to update-talked-to [partner]
  set talked-to lput [who] of partner talked-to
end

to-report accept-interaction? [dist]
  ;; check if normalised dist is smaller than my epsilon
  ;; BE add in a scaling factor -- tollerance-scaling
  if tollerance-scaling = 0 [report false]
  report (dist / (66 * tollerance-scaling)) < (1 - aff-level)
end

to-report sort-out-directions [issue friend]
  ;; agreement: the smaller one moves right (+), the larger one moves left (-)
  ;; disagreement: the smaller one moves further left (-), the larger one moves further right (+)
  let mostly-agree? agree-on-other-issues? issue self friend
  let value item issue positions
  let f-value item issue [positions] of friend
  let indices ifelse-value (f-value < value) [[1 0]][[0 1]]  ;; first position is the smaller, last is the bigger, 0 is me, 1 is friend
  let signs [0 0]  ;; first is me, last is friend
  ifelse (mostly-agree?) [
    ;; we move towards each other
    set signs replace-item (first indices) signs 1   ;; the smaller one +
    set signs replace-item (last indices) signs -1   ;; the larger one -
    set signs lput 1 signs  ;; add a 1 for agreement --> to be recorded on the link
  ][
    ;; we move away from each other
    set signs replace-item (first indices) signs -1  ;; the smaller one -
    set signs replace-item (last indices) signs 1    ;; the larger one +
    set signs lput -1 signs  ;; add a -1 for disagreement --> to be recorded on the link
  ]
  report signs
end

to-report flavour [issue]
  let it item issue positions
  if it = 0 [report 0]
  report it / abs (it)
;  if (item issue positions > 0) [ report 1 ]  ;; ### what about 0?
;  if (item issue positions < 0) [ report -1]
;  report 0
end

to-report agree-on-issue? [issue voter-a voter-b]
  if ([flavour issue] of voter-a = [flavour issue] of voter-b) [ report true ]
  report false
end

to-report agree-on-other-issues? [issue voter-a voter-b]
  let other-issues remove issue n-values (length model-issues - 1) [i -> i]
  let f-a map [i -> [flavour i] of voter-a] other-issues
  ;;show (word "f-a: " f-a)
  let f-b map [i -> [flavour i] of voter-b] other-issues
  ;;show (word "f-b: " f-b)
  let agreements (map [[a b] -> ifelse-value (a = b) [1][0]] f-a f-b)
  ;;show (word "agreements: " agreements)
  if (sum agreements > length agreements / 2) [report true]
  report false
end

;to influence-friend-old
;  ;; meet a friend and talk about politics, depending on political interest level:
;  ;; 1 very interested
;  ;; 2 fairly
;  ;; 3 a little
;  ;; 4 not at all
;  if (random 4 <= (4 - political-interest) and any? link-neighbors) [  ;; voters with no political interest do not initiate political discussions
;    set inf-count inf-count + 1
;    ;; pick a random friend to talk to
;    let friend one-of link-neighbors
;    ;; voters could be influenced on (a) their positions (b) their saliences (c) their opinions on which party is best for which issue
;    ;; we'll ignore the saliences for now ###
;    ;; if I have opinions try and change theirs to one of mine
;    let oilist opined-issues
;    ifelse (length oilist > 0 and random-float 1 < 0.5) [
;      ;; pick an issue I have an opinion about
;      let i one-of oilist  ;; this is just the issue
;      ;; what do I think is the best party for this?  ### could also just go with any opinion/party on that issue, or worst party...
;      let bestp best-party-for-issue i
;      ask friend [
;        adopt-opinion i bestp measure-of i bestp
;      ]
;    ][
;      ;; pick one of my most important issues (or a random issue if I don't have any mips)
;      ;; and try and make them change their position on that issue (= move closer to my position)
;;      let i ifelse-value (empty? my-issues) [random length my-saliences] [one-of my-issues]
;;      if (item i my-saliences > item i [my-saliences] of friend) and (random 1 < voter-adapt-prob) [
;      ;; -- instead let the current issue salience influence what these two will talk about
;      ;; this is very crude, I'm sure we can improve it...
;      let i sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
;      if (item i my-saliences > item i [my-saliences] of friend) and (random 1 < voter-adapt-prob) [  ;; without the salience check, people all move towards the middle  ### THAT's BECAUSE random 1 < voter-adapt-prob is ALWAYS true (random 1 = 0)
;        ask friend [
;          adjust-position-old i myself
;          adjust-salience i  ;; #### first try to adjust people's saliences: whenever they talk about a topic, let its importance go up (and reduce one other)
;          set talked-about replace-item i talked-about (item i talked-about + 1)
;        ]
;        adjust-salience i
;        set talked-about replace-item i talked-about (item i talked-about + 1)
;      ]
;    ]
;;    ifelse (factbase:size my-opinions > 0 and random-float 1 < 0.5) [
;;      ;; pick an issue I have an opinion about
;;      let i one-of opined-issues
;;      ;; what do I think is the best party for this?
;;      let olist opinions-of-issue i
;;      let bestp best-party-for-issue i
;;      ask friend [
;;        adopt-opinion i bestp item (position bestp reverse parties-of olist) reverse measures-of olist
;;      ]
;;    ][
;;      ;; pick one of my most important issues (or a random issue if I don't have any mips)
;;      ;; and try and make them change their position on that issue
;;      let i ifelse-value (empty? my-issues) [random length my-saliences] [one-of my-issues]
;;      if (item i my-saliences > item i [my-saliences] of friend) and (random 1 < voter-adapt-prob) [
;;        ask friend [
;;          adjust-position i myself
;;        ]
;;      ]
;;    ]
;  ]
;end

to-report most-relevant-issue [voter-a voter-b]
  ;; instead of using Baldassari/Bearman formula, we are letting the current issue salience influence what these two will talk about
  ;; this is very crude, I'm sure we can improve it...
  report sample-empirical-dist current-issue-salience [0 1 2 3 4 5 6]
end

to adopt-opinion [io po mo]
  ;; adopt this opinion if I agree with it -- ### question is, how to operationalise this?
  ;; -- if I don't have an opinion about the issue yet and don't feel strongly about it (low importance)
  ;; -- or if I do have an opinion but agree with the assessment of the party
  ;;    * negative assessment: my propensity to vote for this party is low / I already have negative opinions about this party / my distance from this party on the issue is high
  ;;    * positive assessment: my propensity to vote for this party is high / I have positive opinions about this party / my distance to this party on the issue is low

  ;; for now we'll just go with a re-implemenation of what we did before ####
  ;; so I'll adopt the opinion if I don't have one on the given issue yet
  ;; or if I already have an opinion but like the given party better
  if (closest-party = po or item po pp > 5 or not member? io opined-issues) [
    add-opinion io po mo
    set op-changes op-changes + 1
  ]
  ;; there are other ways to go about this... ###
;  let ilist opined-issues
;  ;; if I don't have an opinion on the given issue
;  if (not member? io ilist) [
;    add-opinion io po mo
;    stop
;  ]
;  ;; if I already have an opinion but I like the given party better
;  if (closest-party = po or item po pp > 5) [
;    add-opinion io po mo
;  ]
end

to adjust-position [issue friend sign]
  set pos-history lput positions pos-history
  set pos-changes pos-changes + 1
  ;; move towards friend's position on issue (or away, depending on sign)
  let value item issue positions
  let f-value item issue [positions] of friend
;  set positions replace-item issue positions ((f-value - value) / 10 + value)
  ;; let dist min (list max-p-move (abs (f-value - value) / 10 ))  ;; don't move further than parties?
  let dist (abs (f-value - value) / 10 )
  let new-pos sign * dist + value
  ;; make sure we do not move beyond the allowed range (-34 / + 34)
  set new-pos min (list 34 max (list -34 new-pos))
  set positions replace-item issue positions (new-pos)
  ;; if repulsed by friend, drop friend link -- question: how fast? After one disagreement? After several? Or how big a disagreement?
  ;; -- we might have to keep track of our reactions, one idea: keep info in link, then we just need to look at the links to see which to drop when
  ;; ### record position adjustment on link ---------------------------------
  let f-who [who] of friend
  let our-link link who f-who
  let c-index ifelse-value (who < f-who) [0][1]  ;; determine where to record (front or back)
  ask our-link [
    let c-list item c-index change
    set c-list replace-item issue c-list (item issue c-list + sign * dist)
    set change replace-item c-index change c-list
  ]

end

;to adjust-position-old [issue friend]
;  set pos-history lput positions pos-history
;  set pos-changes pos-changes + 1
;  ;; move towards friend's position on issue
;  let value item issue positions
;  let f-value item issue [positions] of friend
;;  set positions replace-item issue positions ((f-value - value) / 10 + value)
;  let dist min (list max-p-move (abs (f-value - value) / 10 ));; don't move further than parties?
;  let sign ifelse-value (f-value > value) [1][-1]
;  set positions replace-item issue positions (sign * dist + value)
;end


to adjust-salience [issue]
  ;; since we talked about issue, add one 'point' to its salience
  ;; and take one point away from a random other issue
  ;; -- or more than one point?
  let i-salience item issue my-saliences
  ;let value max-salience-change  ;; let's be constant ###########
  let value min (list floor ((100 - i-salience) / 10) max-salience-change)  ;; let's be variable #########
;  show (word "will adjust my salience " i-salience " by " value)
;  let r-list filter [x -> x != issue] my-issues  ;; ### problem here are guys who don't have any issues at the start, so my-issues is []
  ;; ### instead of filtering my-issues we should filter my-saliences; then we can more easily determine which other salience values are high enough to subtract from
  let s-list replace-item issue my-saliences 0  ;; replace salience of issue we talk about with 0
                                                ;; then we can later check if sum s-list = 0 (instead of empty? r-list)
  if (i-salience <= (100 - value)) [
    set my-saliences replace-item issue my-saliences (i-salience + value)
    ;; only subtract if there is anything to subtract from
    if (sum s-list > 0 and sum my-saliences > 100) [
      ;let j position (one-of filter [x -> x >= value] s-list) s-list  ;; ########## this doesn't work if we have to split value to subtract
                                                                      ;; example: my-saliences is now [100 0 2 0 3 0 0] and s-list is [0 0 2 0 3 0 0] with value = 5
      let c-list filter [x -> x >= value] s-list
      ifelse (not empty? c-list) [
        let j position (one-of c-list) s-list
        set my-saliences replace-item j my-saliences (item j my-saliences - value)
      ][
        ;; split value
        set c-list filter [x -> x > 0] s-list
        while [value > 0 and not empty? c-list] [
          let c first c-list
          set c-list but-first c-list
          set value value - c
          let j position c s-list
          set my-saliences replace-item j my-saliences 0
        ]
      ]
    ]
;    if (not empty? r-list and sum my-saliences > 100) [
;      let j one-of r-list
;      set my-saliences replace-item j my-saliences (item j my-saliences - value)
;    ]
  ]
;  if (not empty? r-list and i-salience <= (100 - value)) [
;    set my-saliences replace-item issue my-saliences (i-salience + value)
;    let j one-of r-list
;    set my-saliences replace-item j my-saliences (item j my-saliences - value)
;  ]
;  ;; if (empty? r-list and i-salience = 0) [ set my-saliences replace-item issue my-saliences 10 ] ;; #### this leads to an absolute majority for the SPÖ. Figure that!
;  if (empty? r-list and i-salience <= (100 - value) and sum my-saliences < 100) [
;    set my-saliences replace-item issue my-saliences (i-salience + value)
;  ]
  ;; update my-issues
  set my-issues update-issues
  ;; update size according to display
  ;update-size
end

to-report update-issues
  ;; determine which 1 to 3 issues have highest salience
  ;; shall we put a threshold on salience, say has to be > 10?
  let s-list my-saliences
  let i-list []
  while [length i-list < 3 and max s-list > 10] [
    let m max s-list
    let i position m s-list
    set i-list lput i i-list
    set s-list replace-item i s-list -1
  ]
  report i-list
end



;; ------------- Voting behaviour stuff ----------------------------------------------------------

to make-party-decision
  (ifelse
    my-strategy = 1 [
      set current-p rational-choice
    ]
    my-strategy = 2 [
      set current-p confirmatory
    ]
    my-strategy = 3 [
      set current-p fast-and-frugal
    ]
    my-strategy = 4 [
      set current-p heuristic-based
    ]
    my-strategy = 5 [
      set current-p go-with-gut
    ]
    [
      set current-p 0
    ]
  )
  ;; change my color to the colour of current-p
  set color item current-p party-colours
  ;; update vote history
  update-vote-history
end

to update-vote-history
  ;; if current-p is different from last entry, add it to vote-history
  if (current-p != first last vote-history) [
    set vote-history lput (list current-p ticks) vote-history
  ]
end

;; strategy 1: rational choice decision-making
to-report rational-choice
  ;; pick party closest on all issues (using plain distance)
  let plist sort parties
  let dlist []
  let pdlist []
  foreach plist [ p ->
;    set dlist lput (weighted-distance-to p) dlist
    set pdlist lput (plain-distance-to p) pdlist
  ]
;  show (word "weighted distance " dlist " to parties " plist)
;  show (word "plain distance " pdlist " to parties " plist)
;  let best position (min dlist) dlist + 1 ;; position returns index in list starting with 0, party ids start with 1
  let best position (min pdlist) pdlist + 1
  report best
end

to-report closest [which-dim]
  let pdlist map [p -> plain-distance-in-dims-to p (list which-dim)] sort parties
  show (word "distances: " pdlist)
  report position (min pdlist) pdlist + 1
end

to-report w-closest [which-dim]
  let pdlist map [p -> weighted-distance-in-dims-to p (list which-dim)] sort parties
  show (word "w-distances: " pdlist)
  report position (min pdlist) pdlist + 1
end

;; strategy 2: confirmatory decision-making
to-report confirmatory
  ;; go with closest party if it exists
  if (closest-party != 0 and degree-of-closeness <= 3) [
    report closest-party
  ]
  ;; if there is none, find the party with most positive measures in my opinions
  let plist opined-parties
  ;; if I have no opinions, report 0
  if (empty? plist) [
    report 0
  ]
  let mlist []
  foreach plist [ p ->
    set mlist lput sum (array:to-list measures-of-party p) mlist
  ]
  let best position (max mlist) mlist
  report item best plist
end

;; strategy 3: fast and frugal decision-making
to-report fast-and-frugal
  ;; pick party closest on 1 or 2 most important issues (using weighted distance)
  let plist sort-on [id] parties
  let dlist []
  let pdlist []
  let num-issues min (list 2 length my-issues)
  let dimensions sublist my-issues 0 num-issues
  foreach plist [ p ->
    set dlist lput (weighted-distance-in-dims-to p dimensions) dlist
    set pdlist lput (plain-distance-in-dims-to p dimensions) pdlist
  ]
;  show (word "weighted distance " dlist " to parties " plist)
;  show (word "plain distance " pdlist " to parties " plist)
  let best position (min dlist) dlist + 1
  report best
end

;; strategy 4: heuristic-based decision-making
to-report heuristic-based
  ;; problem here: it's not one strategy, examples given describe three different ones
  ;; (a) choosing a familiar candidate (pick party most heard about)
  ;; (b) satisficing: if one option meets my needs, don't look into others (pick first party that's "good enough")
  ;; (c) follow recommendations of friends (pick party most popular amongst my friends?)
  ;; -- we'll go with c for now since it's most different from the others
  ;; -- but only if this voter doesn't have a closest-party they actually feel close to (this could resemble (a))
;  if (closest-party > 0 and degree-of-closeness <= 2) [
;    report closest-party
;  ]
  ;; see if I have an opinion which is the best party for my most important issue
;  if (not empty? my-issues) [
;    let best best-party-for-issue first my-issues
;    if (best != 0) [
;      report best
;    ]
;  ]
  ;; check which party my friends will vote for
;  let plist [current-p] of link-neighbors
;  let olist map [x -> occurrences x plist] range length party-names
;  let best position (max olist) olist
;  report best
  report any-of-maj
end

to-report first-of-maj
  let plist [current-p] of link-neighbors
  let olist map [x -> occurrences x plist] range length party-names
  report position (max olist) olist
end

to-report any-of-maj
  let plist [current-p] of link-neighbors
  let olist map [x -> occurrences x plist] range length party-names
  let hp max olist
  let hpx position hp olist
  if (occurrences hp olist > 1) [
    let highestp all-positions-of hp olist
    set hpx one-of highestp
  ]
  report hpx
end

;; strategy 5: gut decision-making
to-report go-with-gut
  let p 0
  ;; we will use the propensities to vote for this
  ;; problem only if all propensities are 0 (sum pp = 0; this is true for 193 of the survey participants)
  if (sum pp = 0) [
    ;; pick closest party if it exists and degree-of-closeness <= 2, or random party -- if prob-vote > 4
    if (prob-vote > 4) [
      ifelse (closest-party != 0 and degree-of-closeness <= 2) [
        set p closest-party
      ][
        set p [id] of one-of parties
      ]
    ]
    report p
  ]
  ;; pick the party with highest propensity
  ;; -- if there is a tie, pick the party the voter feels closest to (if degree-of-closeness <= 2), otherwise choose randomly between them
  let hp max pp
  set p position hp pp ;; first entry in pp is for "NULL" party, so the other entries match the party id
  if (occurrences hp pp > 1) [
    let highestp all-positions-of hp pp
    ifelse (member? closest-party highestp and degree-of-closeness <= 2) [
      ;; closest party is one of the highest propensity ones --> take it!
      set p closest-party
    ][
      ;; pick a random one out of the highest propensity ones
      set p one-of highestp
    ]
  ]
  report p
end

;; ------------- utils for opinions -------------------------------------------------------------

to-report opined-parties
  ;; all parties for whom there is at least one measure (not 0) for an issue
  let oplist []
  foreach range (length model-issues - 1) [ i ->
    foreach range (length party-names) [ j ->
      if (measure-of i j != 0 and not member? j oplist) [
        set oplist lput j oplist
      ]
    ]
  ]
  report oplist
end

to-report opined-issues
  ;; any issue where the party array is not all 0
  let oilist []
  foreach range (length model-issues - 1) [ i ->
    let plist array:to-list array:item my-opinions i
    if (not empty? filter [j -> j != 0] plist) [
      set oilist lput i oilist
    ]
  ]
  report oilist
end

to-report measure-of [oissue oparty]
  report array:item (array:item my-opinions oissue) oparty
end

to add-opinion [oissue oparty omeasure]
  array:set (array:item my-opinions oissue) oparty omeasure
  set op-history lput (list oissue oparty omeasure) op-history
end

to-report measures-of-issue [oi]
  ;; report the array of party measures (column oi)
  report array:item my-opinions oi
end

to-report measures-of-party [op]
  ;; turn all measures related to the party into an array (row op)
  let ilist []
  foreach range (length model-issues - 1) [ i ->
    set ilist lput measure-of i op ilist
  ]
  report array:from-list ilist
end

to-report opinions-of-issue [oi]
  ;; turn entries in party array (column oi) <> 0 into opinion lists and return a list of opinions
  let olist []
  foreach range (length party-names) [ p ->
    let m measure-of oi p
    if (m != 0) [
      set olist lput (list oi p m) olist
    ]
  ]
  report olist
end

to-report opinions-of-party [op]
  ;; turn entries in issue array (row op) <> 0 into opinion lists and return a list of opinions
  let olist []
  foreach range (length model-issues - 1) [ i ->
    let m measure-of i op
    if (m != 0) [
      set olist lput (list i op m) olist
    ]
  ]
  report olist
end

to-report best-party-for-issue [i]
  let iolist opinions-of-issue i  ;; these are all my opinions on the issue
  if (empty? iolist) [ report 0 ]
  let plist parties-of iolist
  let mlist measures-of iolist
  let mm max mlist
  let mp position mm mlist
  if (occurrences mm mlist > 1) [ ;; there's a tie in my opinions on who's the best party for the issue
    let all-mp all-positions-of mm mlist
    set mp one-of all-mp          ;; pick randomly between them
  ]
  report item mp plist
end


;to-report opined-parties
;  let result factbase:retrieve-to my-opinions [true][]["party"]
;  report flatten-u result ;;list-to-set flatten result
;end
;
;to-report opined-issues
;  let result factbase:retrieve-to my-opinions [true][]["issue"]
;  report flatten-u result
;end
;
;to-report measures-of-party [p]
;  ;; find and report all measures related to the given party
;  let result factbase:retrieve-to my-opinions [x -> x = p]["party"]["measure"]
;  report flatten result
;end
;
;to-report opinions-of-party [p]
;  ;; find all opinions related to the given party
;  report factbase:retrieve my-opinions [x -> x = p]["party"]
;end
;
;to-report opinions-of-issue [i]
;  ;; find all opinions related to the given issue
;  report factbase:retrieve my-opinions [x -> x = i]["issue"]
;end
;
;to-report recent-opinions-of-party [p time-period]
;  ;; find all opinions related to the given party within the last time-period
;  report factbase:retrieve my-opinions [[x t] -> x = p and t >= ticks - time-period]["party" "tick"]
;end
;
;to-report best-party-for-issue [i]
;  let iolist opinions-of-issue i  ;; these are all my opinions on the issue, with newest opinion last
;  if (empty? iolist) [ report 0 ]
;  let plist parties-of iolist
;  let mlist measures-of iolist
;  let best position (max mlist) reverse mlist
;  report item best reverse plist
;end
;
to-report issues-of [olist]
  report map [x -> i-of x] olist
end

to-report parties-of [olist]
  report map [x -> p-of x] olist
end

to-report measures-of [olist]
  report map [x -> m-of x] olist
end


to-report i-of [o]
  report first o
end

to-report p-of [o]
  report first but-first o
end

to-report m-of [o]
  report last but-last o
end

;to-report time-of [o]
;  report last o
;end
;
;to add-opinion [o-issue o-party o-measure]
;  factbase:assert my-opinions (list o-issue o-party o-measure ticks)
;end
;
;to remove-opinion [o]
;end

;; ------------- Social network stuff ------------------------------------------------------------

to-report vpdist
  let vmap map [i -> mean [item i positions] of voters] [0 1 2 3 4 5 6 7]  ;; mean voter position on each dimension
  let pmap []
  foreach sort parties [ p ->
    set pmap lput map [i -> sqrt (([item i positions] of p - item i vmap) ^ 2)] [0 1 2 3 4 5 6 7] pmap
  ]
  report pmap
end


to create-social-network
  if network-type = "homophily-based political discussion network" [ create-homophily-political-discussion-network ]
  if network-type = "regular random network" [ create-regular-random-network ]
  if network-type = "Erdös-Rényi random network" [ create-erdos-renyi-network ]
  if network-type = "preferential attachment" [ create-pref-attachment-network ]
end

;; basic link creation
to connect-with [the-other]
  create-link-with the-other [
    set hidden? true
    set color 2
    set change [[0 0 0 0 0 0 0][0 0 0 0 0 0 0]]
    set outcomes []
  ]
end

;to-report degree-of-discontent [o-list]
;  report occurrences -1 o-list
;end

to create-pref-attachment-network
  ;; start by connecting the first two voters
  ask one-of voters [ connect-with one-of other voters ]
  while [count voters > count voters with [any? link-neighbors]] [ ;; still some unattached voters around
    ;; pick a random unattached one and find him a partner
    ask one-of voters with [not any? link-neighbors] [
      connect-with find-partner
    ]
  ]
end

;; This code is adapted from Lottery Example (in the Code Examples
;; section of the Models Library).
;; The idea behind the code is a bit tricky to understand.
;; Basically we take the sum of the degrees (number of connections)
;; of the turtles, and that's how many "tickets" we have in our lottery.
;; Then we pick a random "ticket" (a random number).  Then we step
;; through the turtles to figure out which node holds the winning ticket.
to-report find-partner
  let total random-float sum [count link-neighbors] of voters   ;; don't understand why random-float instead of random-int
  let partner nobody
  ask voters with [any? link-neighbors]
  [
    let nc count link-neighbors
    ;; if there's no winner yet...
    if partner = nobody
    [
      ifelse nc > total
        [ set partner self ]
        [ set total total - nc ]
    ]
  ]
  report partner
end

;; Form an Erdos-Renyi random graph -
;;   each configuratoin of the same
;;   degree is equally probable
to create-erdos-renyi-network
  let plink number-of-friends / count voters
  let degree 0
  while [degree < number-of-friends] [
    let fromV one-of voters
    ask fromV [
      let toV one-of other voters
      if not link-neighbor? toV [
        ;; make a link
        connect-with toV
        ;; re-compute mean degree
        set degree mean-degree
      ]
    ]
  ]
end

;; compute mean degree
to-report mean-degree
  if count voters > 0 [
    report mean [count link-neighbors] of voters
  ]
  report 0
end

;; Form a regular random network - each
;;   node has exactly number-of-friends
;;   links.
to create-regular-random-network
  ;; each voter has exactly number-of-friends links (well, as exactly as possible)
  ask voters [
    r-link-voters
  ]
end


to r-link-voters
  ;; loop until this voter has the right number of links (or there aren't any more available voters)

;  while [(count my-links) < number-of-friends and any? voters with [count link-neighbors < number-of-friends]] ;; This is impossibly slow !!
  ;; so reverted back to version found in FriendshipGameRev_1_0_25.nlogo
  let counter 0
  while [count my-links < number-of-friends and 10 * number-of-friends > counter]
  [
    set counter counter + 1
    let friend one-of other voters with [count link-neighbors < number-of-friends]
    if friend != nobody [ connect-with friend ]
  ]
end

to create-homophily-political-discussion-network
  ask voters [
    make-links random 3 ;; 5
  ]
end

to make-links [n]
  repeat n [
    ;; pick some candidates
    let candidates sort n-of 10 other voters
    make-new-link candidates
  ]
end

to make-new-link [candidate-list]
  ;; if candidate-list is empty, do nothing
  if (empty? candidate-list) [ stop ]
  ;; form a link with the most similar one of the possible new friends
  connect-with most-similar candidate-list
end

to evolve-network
  ask voters [
    ;; drop links where there is too much disagreement
    if drop-threshold != 0 [
      ask my-links with [occurrences -1 outcomes > drop-threshold] [
        set counter-dl counter-dl + 1
        die
      ]
    ]
    ;; make a new link
    if (probability new-link-prob) [
      ;;  with a friend of a friend
      ifelse (any? link-neighbors and probability fof-prob) [
        let fof one-of [link-neighbors] of one-of link-neighbors
        if (fof != self) [   ;; can't make a link with myself
          connect-with fof
          set counter-nfl counter-nfl + 1
        ]
      ] [
        let nl count my-links
        ;; with a random guy
        connect-with one-of other voters
        if (count my-links > nl) [
          set counter-nrl counter-nrl + 1
        ]
      ]
    ]
  ]
end

;to evolve-network-old
;  ask voters [
;    ifelse (any? link-neighbors) [
;      ;; make a new link with most similar friend of a friend
;      if (probability 0.1) [ make-new-link get-friend-list one-of link-neighbors]
;      ;; drop least similar of friends
;      if (probability 0.1) [ drop-link ]
;    ][
;      ;; find someone to talk to
;      if (probability 0.2) [ make-new-link (sort n-of 10 other voters) ]
;    ]
;  ]
;end

to-report get-friend-list [friend]
  ;; remove myself from the list of link-neighbors
  let lf [link-neighbors] of friend
  report sort other lf
end

to drop-link
  let ls least-similar sort link-neighbors
  ask one-of my-links with [other-end = ls] [ die ]
end

to-report least-similar [candidate-list]
  let scores map [x -> similarity-score x] candidate-list
  let index position (max scores) scores  ;; the bigger the score, the less similar
  report item index candidate-list
end

to-report most-similar [candidate-list]
  let scores map [x -> similarity-score x] candidate-list
  let index position (min scores) scores ;; the smaller the score, the more similar
  report item index candidate-list
end

to-report similarity-score [another]
  ;; see how similar the other is to myself in education, residential-area and age
  let age-dist abs (age - [age] of another) / 80
  let ed-dist abs (education-level - [education-level] of another) / 15    ;; #### needs to be adapted to other countries' data (15 is number of categories in AUTNES)
  let res-dist abs (residential-area - [residential-area] of another) / 5  ;; ####  (5 is number of categories in AUTNES)
  report age-dist + ed-dist + res-dist
end

to-report mean-similarity
  if (not any? my-links) [ report 0 ]
  report mean map [x -> similarity-score x] ([other-end] of my-links)
end

to-report max-similarity
  if (not any? my-links) [ report 0 ]
  report max map [x -> similarity-score x] ([other-end] of my-links)
end

to-report min-similarity
  if (not any? my-links) [ report 0 ]
  report min map [x -> similarity-score x] ([other-end] of my-links)
end

to toggle-link-visibility
  ifelse ([hidden?] of one-of links) [
    ask links [set hidden? false]
  ][
    ask links [set hidden? true]
  ]
end

to-report count-my-triads
  let ml [who] of link-neighbors
  let visited []
  let c 0
  foreach sort link-neighbors [n ->
    let nl [[who] of link-neighbors] of n
    set visited lput nl visited
    foreach nl [wnl ->
      if (member? wnl ml and not member? wnl visited) [
        set c c + 1
      ]
    ]
  ]
  report c / 2
end

;; --------------- visualisation  ----------------------------------------------------------------------------------------------------------

to redraw-world
  ;; change dimensions if necessary
  if (first current-display-issues != x-issue or last current-display-issues != y-issue) [
    change-dimensions
    set current-display-issues replace-item 0 current-display-issues x-issue
    set current-display-issues replace-item 1 current-display-issues y-issue
  ]
end

to update-coords
  ;; turtle procedure
  setxy item (position x-issue model-issues) positions item (position y-issue model-issues) positions
end

to update-size
  ;; voter procedure
  let xi position x-issue model-issues
  let yi position y-issue model-issues
  set size (item xi my-saliences + item yi my-saliences) * 0.03
end

to translate-positions [plist with-noise?]
  set positions []
  foreach plist [ p ->
    set positions lput translate-to-vis (p + ifelse-value (with-noise?)[add-some-noise][0]) positions
  ]
end

to change-dimensions
  ;; ask both parties and voters to change their xcor and ycor to displayed issues
  ask voters [
    update-coords
    ;update-size
  ]
  ask parties [
    update-coords
  ]
  ask governments [
    update-coords
  ]
end

to-report translate-to-vis [coord]
  report precision (coord * 11 - 33) 2
end

to-report translate-from-vis [coord]
  report precision ((coord + 33 ) / 11) 2
end

to-report filter-ph
  ;; voter procedure
  ;; only select positions on display issues (x and y) from the pos-history
  let x-pos map [p -> item (position x-issue model-issues) p] pos-history
  let y-pos map [p -> item (position y-issue model-issues) p] pos-history
  ;; combine x and y
  let fp (map [[x y] -> (list x y)] x-pos y-pos)
  report fp
end

to draw-ph
  ;; if there's nothing to draw, do nothing
  if (empty? pos-history) [stop]
  ;; get a filtered pos-history
  let fp filter-ph
  ;; let the vis-turtle loose on it
  ask vis-turtle [
    set size 1
    set hidden? false
    set color white
    setxy first first fp last first fp
    pen-down
    foreach but-first fp [ c ->
      setxy first c last c
    ]
    pen-up
    set hidden? true
  ]
end

to erase-ph
  ;; if there's nothing to erase, do nothing
  if (empty? pos-history) [stop]
  let fp reverse filter-ph
  ask vis-turtle [
    set hidden? false
    pen-erase
    foreach but-first fp [ c ->
      setxy first c last c
    ]
    pen-up
    set hidden? true
  ]
end

to draw-cross
  ;; draw axes crossing at 0 0
  ask vis-turtle [
    set size 1
    set color white
    set hidden? false
    setxy 0 33
    set heading 180
    pen-down
    fd 66
    pen-up
    setxy -33 0
    set heading 90
    pen-down
    fd 66
    pen-up
    set hidden? true
    setxy 0 0
  ]
end

;; ---------------- distance measures -----------------------------------------------------------------------------------------------------

;; we will establish the government at the beginning and end of the simulation (or: every 4 years after an election)
;; via party-events

;; 1 Likert scale category covers 11 coordinate points in the visualisation
;; so if a voter is at most 1 category width away from the government in ALL dimensions, that's sqrt (7 * 11 ^ 2) = 29.1032 --> 30
;; --- this seems a better value to use than the mean distance to use as a measure of voter "happiness" with the government
;; the problem with the most important issues are the weights assigned to the issues
;; if a voter assigns 50-50 and is at most 1 category width away from the government in the two dimension, that's sqrt (2 * 0.5 * (11 ^ 2)) = 11
;; if a voter has more than 2 important categories, the sum of the weights will be < 1 and the distance value < 11, so 11 is the maximum distance
;; for happiness in most-important issues

to-report compute-distance-measures

  ;; compute mean dist-all-equal (rational choice)
  let rc mean [dist-all-equal-to the-gov] of voters
  ;; compute mean dist-most-important (fast and frugal)
  let ff mean [dist-most-important-to the-gov] of voters
  ;; compute % of voters with distance <= 30
  let n count voters
  let rc-prop count voters with [dist-all-equal-to the-gov <= 29.1] / n
  ;; compute % of voters with distance <= ff
  let ff-prop count voters with [dist-most-important-to the-gov <= 11] / n

  report (list rc rc-prop ff ff-prop)
end

to-report num-issues-close-to [pid]
  ;; compute number of issues I am close = max 1 category width away from the given party
  let nic 0
  let ci n-values (length model-issues - 1) [0]
  foreach range (length model-issues - 1) [ i ->
    if (plain-distance-in-dims-to pid (list i) < 11) [
      set nic nic + 1
      set ci replace-item i ci 1
    ]
  ]
  report ci
end

to-report most-important [num-i]
  ;; first check that num-i is not too big
  set num-i min (list num-i 7)
  ;; report the first num-i most important issues
  let sorted-sal sort my-saliences
  let mi n-values (length model-issues - 1) [0]
  foreach range num-i [ i ->
    ;; retrieve issue (if salience > 0), biggest salience is in back of sorted list
    let s last sorted-sal
    set sorted-sal but-last sorted-sal
    if (s > 0) [
      let s-index position s my-saliences
      set mi replace-item s-index mi 1
    ]
  ]
  report mi
end



to-report dist-most-important-to [pid]
  let num-issues min (list 2 length my-issues)
  if num-issues = 0 [ report 0 ]
  let dimensions sublist my-issues 0 num-issues
  report (weighted-distance-in-dims-to pid dimensions) ;;/ num-issues
end

to-report dist-all-equal-to [pid]
  report plain-distance-to pid ;;/ (length model-issues - 1)  ;; ignore left-right issue
end

to-report possible-gov
  let sp sort-on [last vote-share] parties
  ;; add vote-shares starting from highest parties = end of the sorted list
  let s 0
  let gov []
  while [s < 48] [
    set s s + [last vote-share] of last sp
    set gov lput last sp gov
    set sp but-last sp
  ]
  report gov
end

to change-gov
  ask parties [set gov? false]
  ask turtle-set possible-gov [set gov? true]

  set the-gov create-a-gov
end

to-report create-a-gov
  ask governments [die]

  create-governments 1 [
    set size 2
    set color white
    set shape "wheel"
    set name "government"
    set hidden? true
    set coalition map [i -> [who] of i] in-government
    set vote-share (list government-vote-share)
    set positions weighted-government-positions ;; use weighted positions
    update-coords
  ]

  report one-of governments
end

to-report in-government
  report filter [p -> [gov?] of p] sort parties
end

to-report government-position-on [issue gplist]
  ;; assuming average position on the given issue between all governing parties
  let glist map [p -> [item issue positions] of p] gplist
  report mean glist
end

to-report weighted-government-position-on [issue gplist gpweights]
  ;; assuming weighted average positions (weighted with 'size' of coalition partner)
  let glist map [p -> [item issue positions] of p] gplist
  set glist (map * glist gpweights)
  report sum glist
end

to-report government-positions
  ;; report list of positions on all issues
  let gparties in-government ;; compute this only once instead of every time when calling government-position-on
  report map [i -> government-position-on i gparties] (range 0 length model-issues)
end

to-report weighted-government-positions
  ;; report list of positions on all issues
  let gparties in-government ;; compute this only once instead of every time when calling government-position-on
  let t sum [last vote-share] of turtle-set gparties
  let gweights map [p -> ([last vote-share] of p) / t] gparties
  report map [i -> weighted-government-position-on i gparties gweights] (range 0 length model-issues)
end

to-report government-vote-share
  ;; sum of coalition vote shares
  let s 0
  foreach in-government [ g ->
    set s s + [last vote-share] of g
  ]
  report s
end

;; --------------- utils -------------------------------------------------------------------------------------------------------------------

;; algorithm from here: https://en.wikipedia.org/wiki/Cluster_analysis#Grid-based_clustering
;; threshold determines if a cell (patch) counts as a cluster or not: if the number of voters is <= threshold, the patch does not belong to a cluster
to-report grid-cluster-analysis [threshold]
  ask patches [
    set traversed? false
    set cluster 0
  ]
  let current-c 0 ;; current cluster-id
  while [any? patches with [not traversed?]] [
    ;; pick a random non-traversed cell
    let cell one-of patches with [not traversed?]
    ;show (word "inspecting cell " cell)
    ;; mark as traversed
    ask cell [set traversed? true]
    if [count voters-here] of cell > threshold [
      set current-c current-c + 1
      ;show (word "found cluster " current-c)
      ;; mark as new cluster
      ask cell [set cluster current-c]
      let expand-set []
      foreach sort ([neighbors] of cell) with [not traversed?] [n-cell ->
        ;; mark as traversed
        ask n-cell [set traversed? true]
        if [count voters-here] of n-cell > threshold [
          ;; add to cluster
          ask n-cell [set cluster current-c]
          ;; add to expand set (have to investigate its neighbours)
          set expand-set lput n-cell expand-set
        ]
      ]
      while [not empty? expand-set] [
        let e-cell first expand-set
        set expand-set but-first expand-set
        foreach sort ([neighbors] of e-cell) with [not traversed?] [n-cell ->
          ;; mark as traversed
          ask n-cell [set traversed? true]
          if [count voters-here] of n-cell > threshold [
            ;; add to cluster
            ask n-cell [set cluster current-c]
            ;; add to expand-set if not already in there
            if (not member? n-cell expand-set) [ set expand-set lput n-cell expand-set ]
          ]
        ]
      ]
    ]
  ]
  show (word "found " current-c " clusters")
  let cv count voters-on patches with [cluster > 0]
  let cvp cv / count voters
  show (word precision (cvp * 100) 2 "% voters in clusters")
  ;report (word current-c "," cvp)
  let result map [i -> count voters-on patches with [cluster = i]] range (current-c + 1)
  set result fput cvp result
  set result fput current-c result
  report (list result)
end

to cyes  ;; show clusters
  ask voters [set size 0.43 set shape "circle"]
  ask patches with [cluster > 0] [set pcolor black]
end

to cno  ;; un-show clusters
  ask patches [set pcolor 5]
  ask voters [set shape "person" set size age * 0.025]
end

to-report dist-p
  let my-list map [i -> plain-distance-to i] sort parties
  set my-list fput current-p my-list
  set my-list fput who my-list
  report my-list
end

to-report avg-pos-of-voters-on [issue]
  ;; calculate average position of all voters on the given issue
  report mean [item issue positions] of voters
end

to-report avg-pos-of-supporters-on [party-id issue]
  ;; calculate average position of party supporters on the given issue
  report mean [item issue positions] of voters with [current-p = party-id]
end

to-report list-for-csv [a-list]
  let outstr ""
  foreach a-list [i ->
    set outstr (word outstr i ",")
  ]
  report but-last outstr
end

to-report avg-voter-pos
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> avg-pos-of-voters-on i] [0 1 2 3 4 5 6]
end

to-report avg-supporter-pos [party-id]
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> avg-pos-of-supporters-on party-id i] [0 1 2 3 4 5 6]
end

to-report median-supporter-pos [party-id]
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> median [item i positions] of voters with [current-p = party-id]] [0 1 2 3 4 5 6]
end

to-report max-supporter-pos [party-id]
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> max [item i positions] of voters with [current-p = party-id]] [0 1 2 3 4 5 6]
end

to-report min-supporter-pos [party-id]
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> min [item i positions] of voters with [current-p = party-id]] [0 1 2 3 4 5 6]
end

to-report median-voter-pos
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> median [item i positions] of voters] [0 1 2 3 4 5 6]
end

to-report max-voter-pos
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> median [item i positions] of voters] [0 1 2 3 4 5 6]
end

to-report min-voter-pos
  ;; to be used in BehaviourSpace experiments
  report list-for-csv map [i -> median [item i positions] of voters] [0 1 2 3 4 5 6]
end

to-report main-pos-of [a-turtle]
  if (is-voter? a-turtle) [
    report [print-pos-on my-issues] of a-turtle
  ]
  if (is-party? a-turtle) [
    ifelse ([who] of a-turtle = 2) [
      report [print-pos-on [3 2 0]] of a-turtle
    ][
     report [print-pos-on our-issues] of a-turtle
    ]
  ]
  report ""
end

to-report print-pos-on [issues]
  ;; turtle procedure
  let outstr ""
  foreach issues [i ->
    set outstr (word outstr (item i positions) ",")
  ]
  report but-last outstr
end

to-report salience-prop [issue]
  report sum [item issue my-saliences] of voters / sum [sum my-saliences] of voters * 100
end

to-report ph-stats [dim]
  ;; give statistics on the movement in dimension dim
  let pdim map [p -> item dim p] pos-history
  set pdim lput item dim positions pdim ;; add current position
  ;; find min, max positions, average distance per move, current distance from start
  let pmin min pdim
  let pmax max pdim
  let pcur last pdim - first pdim
  let pdist []
  foreach n-values (length pdim - 1) [i -> i] [ i ->
    set pdist lput abs ((item (i + 1) pdim) - (item i pdim)) pdist
  ]
  let davg 0
  let dmax 0
  let dmin 0
  if (not empty? pdist) [
    set davg mean pdist
    set dmax max pdist
    set dmin min pdist
  ]
  ;; report original position, minimum (furthest left) position, maximum (furthest right position), current position,
 ;;         min distance in a move, max distance in a move, average dist per move, distance between original and current position
  report (list (first pdim) pmin pmax (last pdim) dmin dmax davg pcur)
end

to-report probability [p-value]
  report (random-float 1.0 < p-value)
end

to-report all-positions-of [value alist]
  ;; find all positions of value in the given list
  let result []
  if (not member? value alist) [ report result ]
  let i position value alist
  let j 0
  while [i != false and j < length alist] [
    set result lput (i + j) result
    set j j + i + 1
    set i position value sublist alist j length alist
  ]
  report result
end

to-report flatten [lol]
  ;; lol is a list of lists with single elements
  let result []
  foreach lol [ l ->
    set result lput first l result
  ]
  report result
end

to-report list-to-set [the-list]
  ;; turn list into set = list with only unique elements
  let the-set []
  foreach the-list [ l ->
    if (not member? l the-set) [ set the-set lput l the-set ]
  ]
  report the-set
end

to-report flatten-u [lol]
  ;; lol is a list of lists with single elements
  ;; report unique elements (set of flattened list)
  ;; -- this is probably faster than list-to-set flatten lol because we only go through the list once
  let result []
  foreach lol [ l ->
    let fl first l
    if (not member? fl result) [ set result lput fl result ]
  ]
  report result
end

to-report flatten-all-u [lol]
  ;; lol is a list of lists with more than one element
  ;; report unique elements (set of flattened list)
  let result []
  foreach lol [ l ->
    foreach l [ le ->
      if (not member? le result) [ set result lput le result ]
    ]
  ]
  report result
end

to-report plain-distance-to [another]
 ;; compute n-dimensional distance over all positions (except the left-right one)  ## have to ignore the left-right one because it is never changed!
  report plain-distance-in-dims-to another n-values (length positions - 1) [j -> j]
end

to-report weighted-distance-to [another]
  ;; compute weighted n-dimensional distance over all positions (except the left-right one)
  ;; this assumes that my-saliences has weights for ALL positions (some may be 0 of course)
  report weighted-distance-in-dims-to another n-values (length positions - 1) [j -> j]
end

to-report plain-distance-in-dims-to [another dims]
  ;; compute only selected dimensions (issues) given by dims as a list e.g. [0 3 4]
  let d []
  let another-positions [positions] of another
  foreach dims [ i ->
    set d lput ((item i positions - item i another-positions) ^ 2) d
  ]
  report sqrt sum d
;  report sqrt sum (map [[a b] -> (a - b) ^ 2] but-last positions (but-last [positions] of another))
end

to-report weighted-distance-in-dims-to [another dims]
  ;; compute only selected dimensions (issues) given by dims as a list e.g. [0 3 4]
  let d []
  foreach dims [ i ->
    set d lput (item i my-saliences / 100 * (item i positions - item i [positions] of another) ^ 2) d
  ]
  report sqrt sum d
end

to-report proportion-of-party [p]
  ;; observer procedure
  let n count voters
  if (n = 0) [ report 0 ]
  report count voters with [current-p = p] / n * 100
end

to-report positions-of-party [p]
  report [positions] of party p
end

to-report pos-history-of [entity issue]
  ;; extract all positions on the given issue from pos-history
  report map [x -> item issue x] [pos-history] of entity
end

to-report mean-party-changes-per-strategy [s]
  let sv voters with [my-strategy = s]
  if (not any? sv) [ report 0 ]
  report mean [length vote-history - 1] of sv
end

to-report get-a-mip
  report sample-empirical-dist voter-mip-probs n-values (length voter-mip-probs) [i -> i]
end

;;; count the number of occurrences of an item in a list
;to-report old-occurrences [x the-list]
;  report reduce
;    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
;end
;
;to-report an-occurrences [x the-list]
;  report sum map [? -> ifelse-value (x = ?) [1] [0]] the-list
;end

to-report occurrences [x the-list]
 if not member? x the-list [report 0]
 report 1 + occurrences x (sublist the-list (1 + position x the-list) length the-list)
end

;to-report occurrences [x the-list]
;  ;; a faster version :-)
;  if not member? x the-list [report 0]
;  let ps position x the-list
;  report 1 + occurrences x (after ps the-list)
;end
;
;to-report after [ps alist]
;  report sublist alist (ps + 1) length alist
;end

to-report sample-empirical-dist [probabilities values]
  ;; probabilities are not accumulated but add up to 1.0
  ;; there is a probability for each value
  let k random-float 1.0
  let i 0
  let lower-bound 0
  while [i < length probabilities] [
    ifelse (k < precision (lower-bound + item i probabilities) 4) [
      report item i values
    ] [
      set lower-bound precision (lower-bound + item i probabilities) 4
      set i i + 1
    ]
  ]
  show (word "ERROR in sample-empirical-distribution with probs " probabilities " and values " values " // k = " k " and i = " i)
  report -1
end

to-report t-abweichung
  ;; reports total distortion
  let n-pos map [i -> round (translate-from-vis i)] positions
  let abw (map - my-positions n-pos)
  set abw map [i -> abs i] abw
  report sum abw
end

to-report abweichung
  ;; reports number of distorted positions
  let n-pos map [i -> translate-from-vis i] positions
  let abw (map - my-positions n-pos)
  set abw map [i -> abs i] abw
  set abw map [i -> ifelse-value (i <= 0.5) [0][1]] abw
  report sum abw
end

to-report pos-distortion
  ;; reports absolute distortion for each position
  let n-pos map [i -> translate-from-vis i] positions
  let abw (map - my-positions n-pos)
  set abw map [i -> precision i 3] abw
  report abw
end

to-report interaction-matrix
  let n count voters
  let offset min [who] of voters
  let matrix array:from-list map [i -> array:from-list n-values n [0]] n-values n [0]
  ask voters [
    let my-entry array:item matrix (who - offset)
    foreach talked-to [i ->
      let value array:item my-entry (i - offset)
      array:set my-entry (i - offset) (value + 1)
    ]
  ]
  report map [i -> array:to-list i] array:to-list matrix
end

to write-im [fname]
  csv:to-file fname interaction-matrix
end

to-report max-interaction-dist
  ;; depending on my aff-level, how much distance do I accept between me and another voter?
  ;; (dist / 66) < (1 - aff-level) --> dist < (1 - aff-level) * 66
  report (1 - aff-level) * 66
end

to draw-interaction-circle
  let radius max-interaction-dist
  ask vis-turtle [
    pen-up
    move-to myself
    set color white
    fd radius
    rt 90
    pen-down
    repeat 2 * 360 [move-along-circle radius]
    pen-up
  ]
end

to move-along-circle [r]
  fd (pi * r / 180) * 0.5
  rt 0.5
end

;----------------- odd bruce stuff --------------------

to-report hist [lst]
  let ind-list sort remove-duplicates lst
  let op-list []
  foreach ind-list [ind ->
    set op-list lput (list ind occurrences ind lst) op-list
  ]
  report op-list
end
@#$#@#$#@
GRAPHICS-WINDOW
159
10
706
558
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-38
38
-38
38
1
1
1
ticks
30.0

BUTTON
4
37
71
70
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
5
221
72
254
tog links
toggle-link-visibility
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
566
563
707
608
x-issue
x-issue
"economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order" "left-right"
0

CHOOSER
4
173
145
218
y-issue
y-issue
"economy" "welfare state" "spend vs taxes" "immigration" "environment" "society" "law and order"
3

BUTTON
75
222
144
255
update
redraw-world
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
368
562
557
632
Proportions of decision-making strategies:\nRational choice / Confirmatory / Fast and frugal / Heuristics-based\n    / Go with gut
11
0.0
1

PLOT
718
10
1214
200
Voting Poll
time
party proportions
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"null" 1.0 0 -11053225 true "" "plot proportion-of-party 0"
"SPÖ" 1.0 0 -2674135 true "" "plot proportion-of-party 1"
"ÖVP" 1.0 0 -11221820 true "" "plot proportion-of-party 2"
"FPÖ" 1.0 0 -13345367 true "" "plot proportion-of-party 3"
"Greens" 1.0 0 -10899396 true "" "plot proportion-of-party 4"
"BZÖ" 1.0 0 -955883 true "" "plot proportion-of-party 5"
"NEOS" 1.0 0 -2064490 true "" "plot proportion-of-party 6"
"T.Stro" 1.0 0 -1184463 true "" "plot proportion-of-party 7"

BUTTON
4
73
71
106
run
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
6
259
151
292
voter-adapt-prob
voter-adapt-prob
0
1
1.0
0.05
1
NIL
HORIZONTAL

INPUTBOX
132
563
361
623
strategy-proportions
[0.183 0.298 0.385 0.049 0.085]
1
0
String

INPUTBOX
6
574
127
634
party-strategies
[2 2 3 0 0 0 0]
1
0
String

TEXTBOX
8
516
153
573
Strategy for parties:\n0 : sticker, 1 : satisficer, 2 : aggregator, 3 : hunter (one entry per party)
11
0.0
1

MONITOR
721
406
804
451
NIL
inf-count
0
1
11

MONITOR
809
406
892
451
NIL
pos-changes
0
1
11

SLIDER
6
295
151
328
discussion-freq
discussion-freq
0
10
6.0
0.1
1
NIL
HORIZONTAL

SWITCH
362
664
513
697
dynamic-network?
dynamic-network?
0
1
-1000

PLOT
808
577
1008
697
Social network
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-pen-interval 1\nset-plot-x-range 0 15" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [count my-links] of voters"

SLIDER
6
332
153
365
max-p-move
max-p-move
0
2
0.0
0.1
1
NIL
HORIZONTAL

PLOT
977
254
1216
404
Topics talked about
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"economy" 1.0 0 -16777216 true "" "plot sum [item 0 talked-about] of voters / 2"
"welfare state" 1.0 0 -7500403 true "" "plot sum [item 1 talked-about] of voters / 2"
"spend vs tax" 1.0 0 -2674135 true "" "plot sum [item 2 talked-about] of voters / 2"
"immigration" 1.0 0 -13345367 true "" "plot sum [item 3 talked-about] of voters / 2"
"environment" 1.0 0 -13840069 true "" "plot sum [item 4 talked-about] of voters / 2"
"society" 1.0 0 -1184463 true "" "plot sum [item 5 talked-about] of voters / 2"
"law and order" 1.0 0 -6459832 true "" "plot sum [item 6 talked-about] of voters / 2"

PLOT
720
253
974
403
issue salience
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"economy" 1.0 0 -16777216 true "" "plot salience-prop 0"
"welfare state" 1.0 0 -7500403 true "" "plot salience-prop 1"
"spend vs tax" 1.0 0 -2674135 true "" "plot salience-prop 2"
"immigration" 1.0 0 -13345367 true "" "plot salience-prop 3"
"environment" 1.0 0 -13840069 true "" "plot salience-prop 4"
"society" 1.0 0 -1184463 true "" "plot salience-prop 5"
"law and order" 1.0 0 -6459832 true "" "plot salience-prop 6"

MONITOR
720
204
777
249
SPÖ
proportion-of-party 1
2
1
11

MONITOR
783
204
840
249
ÖVP
proportion-of-party 2
2
1
11

MONITOR
845
204
902
249
FPÖ
proportion-of-party 3
2
1
11

MONITOR
907
204
964
249
Grüne
proportion-of-party 4
2
1
11

MONITOR
969
204
1026
249
BZÖ
proportion-of-party 5
2
1
11

MONITOR
1030
204
1087
249
NEOS
proportion-of-party 6
2
1
11

MONITOR
1091
204
1148
249
TS
proportion-of-party 7
2
1
11

MONITOR
1153
204
1215
249
non
proportion-of-party 0
2
1
11

SLIDER
7
370
152
403
max-salience-change
max-salience-change
0
10
3.0
1
1
NIL
HORIZONTAL

BUTTON
75
74
147
107
step
go
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
221
626
373
659
assign-from-data?
assign-from-data?
0
1
-1000

PLOT
1012
454
1212
574
Party changes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-pen-interval 10\nset-plot-x-range 0 150" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [length vote-history] of voters"

INPUTBOX
4
109
146
169
rnd-seed
-2.070687149E9
1
0
Number

CHOOSER
221
700
514
745
network-type
network-type
"homophily-based political discussion network" "regular random network" "Erdös-Rényi random network" "preferential attachment"
1

SLIDER
519
675
659
708
number-of-friends
number-of-friends
0
50
3.0
1
1
NIL
HORIZONTAL

SLIDER
665
711
804
744
drop-threshold
drop-threshold
0
10
10.0
1
1
NIL
HORIZONTAL

MONITOR
809
700
895
745
dropped links
counter-dl
0
1
11

MONITOR
899
701
988
746
new fof links
counter-nfl
0
1
11

MONITOR
993
701
1101
746
new random links
counter-nrl
0
1
11

SLIDER
664
675
803
708
new-link-prob
new-link-prob
0
1
0.007
0.001
1
NIL
HORIZONTAL

PLOT
721
455
1008
575
Distance measures
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mean all-equal" 1.0 0 -16777216 true "" "plot item 0 d-measures"
"% voters 'happy\" with all" 1.0 0 -7500403 true "" "plot item 1 d-measures * 100"
"mean most-important" 1.0 0 -2674135 true "" "plot item 2 d-measures"
"% voters \"happy\" gov" 1.0 0 -955883 true "" "plot item 3 d-measures * 100"

PLOT
1014
577
1214
697
Number of links
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count links"

MONITOR
1104
701
1191
746
lone voters
count voters with [not any? link-neighbors]
0
1
11

SLIDER
518
712
659
745
fof-prob
fof-prob
0
1
0.8
0.1
1
NIL
HORIZONTAL

BUTTON
719
631
800
664
do stats
stats
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
517
626
613
671
av dist v cent v
av-dist-cv-voters
2
1
11

MONITOR
616
626
711
671
av dist p cent v
av-dist-cv-parties
2
1
11

INPUTBOX
75
10
146
70
max-tick
209.0
1
0
Number

SLIDER
7
406
152
439
tollerance-scaling
tollerance-scaling
0
2
1.0
0.1
1
NIL
HORIZONTAL

SWITCH
7
442
152
475
symetric-infl?
symetric-infl?
0
1
-1000

SLIDER
8
478
154
511
ch-aff-fact
ch-aff-fact
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
3
638
215
758
aff-levels
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"set-histogram-num-bars 10\nset-plot-x-range 0 1" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [aff-level] of voters"

@#$#@#$#@
## WHAT IT IS

This is the first version of a model exploring voting behaviour in Austria. The aim of the model is to identify the processes that lead to specific election outcomes. Austria was chosen as a case study because it has an established populist party (the "Freedom Party" FPÖ), which has even been part of the government over the years.

## HOW IT WORKS

The model distinguishes between voters and parties. Both are initialised from publicly available empirical data, the 2013 AUTNES voter survey comprising 3266 individuals and the 2014 Chapel Hill Expert Survey (CHES) comprising 7 parties for Austria. The necessary files are bundled with the model code.

From these surveys we identified seven common issues that are used as the dimensions of the political landscape: economy (pro/against state intervention in the economy), welfare state (pro/against redistribution of wealth), budget (pro/against raising taxes to increase public services), immigration (against/pro restrictive immigration policy), environment (pro/against protection of the environment), society (pro/against same rights for same-sex unions), law and order (against/pro strong measures to fight crime, even to the detriment of civil liberties).

Both voters and parties are located in this landscape by means of their positions on the respective issues. Since seven issues are difficult to visualise in two dimensions, the model only maps two of these issues at a time to the x- and y-axis of the world. The user can choose which ones to display via the model parameters _x-issue_ and _y-issue_ and then pressing the _update_ button.

The parties are represented as wheels and are assigned a colour: SPÖ red, ÖVP blue, FPÖ cyan, BZÖ yellow, The Greens green, NEOS orange, Team Stronach pink. In addition to their positions on the seven issues, they all identify 2-3 of these as their most important issues and assign a weight to them.

The voters are represented as persons; their size grows with age. They adopt the colour of the party they would currently vote for (light grey, if none). Voters are characterised by demographic attributes (age, sex, education level, income level, area of residence), political attitudes (political interest, party they feel closest to and degree of that closeness, propensities to vote for either of the parties). They also have positions on all seven issues (my-positions), identify up to 3 of these issues as most important (my-issues) and assign weights to them according to their importance (my-saliences). In addition, they have opinions on which party is best (or not) to handle a particular issue.

Via their social network (initialised as a mixture of random and homophilic aspects) voters can influence their opinions on parties and/or positions on issues.

Both parties and voters use certain strategies for their decision-making. There are currently five different strategies for voters:
  * rational choice (pick the party closest to them on all seven dimensions)
  * confirmatory (pick the party they feel closest to or are most familiar with)
  * fast and frugal (pick the party closest to them on the two most important issues)
  * heuristics-based (pick the party 'recommended' by most of their friends)
  * go with your gut (operationalised as choosing the party for which they have the highest propensity to vote; taken from the AUTNES survey).

You can specify what mixture of strategies are to be used by stating a proportion for each of them in the model parameter _strategy-proportions_. Note that all five proportions have to sum up to 1 (100%). Strategies are assigned randomly to the voters.

There are four strategies for the parties to choose from:
  * sticker (do not change positions)
  * satisficer (stop moving when the aspired vote share is reached or surpassed)
  * aggregator (move towards the average position of supporters on all seven dimensions)
  * hunter (keep moving in the same direction if the last move increased vote share; otherwise turn around and pick a new direction randomly from the 180° arc in front. Only the two most important issues for the party are taken into account.

You can specify which strategy each party should use by adapting the list in the model parameter _party-strategies_.


## HOW TO USE IT

Press the **setup** button, then either **step** (for one time step at a time) or **go**. Watch the simulation unfold in the world (voters changing colour according to their current favourite party) and the election poll timeline.


## THINGS TO TRY

To explore the different dimensions ("issues") of the political landscape you can pick which of them should be displayed by selecting one for each of the model parameters x-issue and y-issue, respectively.

## EXTENDING THE MODEL

This is a work in progress. Our next steps will be to include the influence of the media on voter behaviour and different strategies for parties to change their position(s) in the political landscape.


## CREDITS AND REFERENCES

This model is Deliverable 2.2 of the PaCE (Populisam and Civic Engagement) project, see http://popandce.eu/. Funded by the EU H2020 initiative under grant agreement ID: 822337.
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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="network-types x tollerance-scaling x ch-aff-fact" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="2"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="tollerance-scaling" first="0" step="0.5" last="2"/>
    <steppedValueSet variable="ch-aff-fact" first="0" step="0.2" last="1"/>
  </experiment>
  <experiment name="network-types x voter adapt prob" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x discussion-freq" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.5" last="5"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x max-p-move" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-p-move" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x max-salience-change" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x new-link-prob" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="new-link-prob" first="0" step="0.001" last="0.01"/>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x number-of-friends" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-friends" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x drop-threshold" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <steppedValueSet variable="drop-threshold" first="0" step="1" last="10"/>
  </experiment>
  <experiment name="network-types x voter adapt prob - non dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x discussion-freq - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.5" last="5"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x max-p-move - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-p-move" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x max-salience-change - non dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x number-of-friends - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-friends" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types voter-ad vs disc-freq" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types disc-freq vs max-p-move" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types max-p-move vs max-sal-ch" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types max-sal-ch vs vot-adapt" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types voter-ad vs max-p-mov" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types disc-freq vs max-sal-ch" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types disc-freq vs max-p-move - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types disc-freq vs max-p-move - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types max-sal-ch vs vot-adapt - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types max-sal-ch vs vot-adapt - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types voter-ad vs max-p-mov - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-p-move" first="0" step="0.2" last="1"/>
    <steppedValueSet variable="voter-adapt-prob" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types disc-freq vs max-sal-ch - non-dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="discussion-freq" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-salience-change" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types x toll x ch-aff (small)" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ch-aff-fact" first="0" step="0.025" last="0.25"/>
    <steppedValueSet variable="tollerance-scaling" first="0" step="0.2" last="2"/>
  </experiment>
  <experiment name="network-types" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types ch-aff=0.2 new-link x drop thresh" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="new-link-prob" first="0" step="0.002" last="0.01"/>
    <enumeratedValueSet variable="drop-threshold">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types - network duals" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.001"/>
      <value value="0.003"/>
      <value value="0.007"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="1"/>
      <value value="3"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types - other duals" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="1.5"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types - duals all" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.003"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="3"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0.1"/>
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network-types - non dyn - toll x ch-aff" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="tollerance-scaling" first="0" step="0.5" last="2"/>
    <steppedValueSet variable="ch-aff-fact" first="0" step="0.2" last="1"/>
  </experiment>
  <experiment name="standard - parties do not move" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="standard - non dyn" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="standard - talk only to close" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="standard" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="standard - networks" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>av-dist-cv-voters</metric>
    <metric>av-dist-cv-parties</metric>
    <metric>item 0 d-measures</metric>
    <metric>item 1 d-measures</metric>
    <metric>item 2 d-measures</metric>
    <metric>item 3 d-measures</metric>
    <metric>proportion-of-party 1</metric>
    <metric>proportion-of-party 2</metric>
    <metric>proportion-of-party 3</metric>
    <metric>proportion-of-party 4</metric>
    <metric>proportion-of-party 5</metric>
    <metric>proportion-of-party 6</metric>
    <metric>proportion-of-party 7</metric>
    <metric>proportion-of-party 0</metric>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1015627543"/>
      <value value="-1726988270"/>
      <value value="-1882066735"/>
      <value value="1874088100"/>
      <value value="-2114034407"/>
      <value value="-1894242236"/>
      <value value="-229467457"/>
      <value value="-1055753174"/>
      <value value="1018134947"/>
      <value value="-1163317169"/>
      <value value="-696704274"/>
      <value value="-1488581867"/>
      <value value="401877338"/>
      <value value="575024468"/>
      <value value="-1771356229"/>
      <value value="2017911993"/>
      <value value="1328477984"/>
      <value value="-2061566840"/>
      <value value="-848834428"/>
      <value value="1605867051"/>
      <value value="1821645423"/>
      <value value="-1987369792"/>
      <value value="1480875488"/>
      <value value="2035997352"/>
      <value value="1982751490"/>
      <value value="117169065"/>
      <value value="1964937471"/>
      <value value="814757595"/>
      <value value="2013573225"/>
      <value value="-223017142"/>
      <value value="1171394281"/>
      <value value="1565904579"/>
      <value value="1533113963"/>
      <value value="423667507"/>
      <value value="-2041010965"/>
      <value value="532884607"/>
      <value value="2017547801"/>
      <value value="879869396"/>
      <value value="1860017391"/>
      <value value="1653700855"/>
      <value value="-730887763"/>
      <value value="-769644035"/>
      <value value="175112531"/>
      <value value="612960058"/>
      <value value="293245335"/>
      <value value="212972188"/>
      <value value="-382413704"/>
      <value value="-1520949475"/>
      <value value="-1586301806"/>
      <value value="-309403097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;homophily-based political discussion network&quot;"/>
      <value value="&quot;regular random network&quot;"/>
      <value value="&quot;preferential attachment&quot;"/>
      <value value="&quot;Erdös-Rényi random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="standard" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="rnd-seed">
      <value value="-2070687149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ch-aff-fact">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voter-adapt-prob">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tollerance-scaling">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tick">
      <value value="209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="-2070687149"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fof-prob">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symetric-infl?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy-proportions">
      <value value="&quot;[0.183 0.298 0.385 0.049 0.085]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;regular random network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-salience-change">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assign-from-data?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="x-issue">
      <value value="&quot;economy&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-strategies">
      <value value="&quot;[2 2 3 0 0 0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop-threshold">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="y-issue">
      <value value="&quot;immigration&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discussion-freq">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-p-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-link-prob">
      <value value="0.007"/>
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
