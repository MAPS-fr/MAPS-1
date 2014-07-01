extensions [gis]
globals
  [OSmin                                                                    ; definition de toutes les variables globales
  nbcluster
  Htotal
  TpsMoyOS1
  som1
  moy1
  listoccOS1
  tpsmoyen1
  som2
  moy2
  listoccOS2
  tpsmoyen2
  som3
  moy3
  listoccOS3
  tpsmoyen3
 Ishannon
 FraG
 majofam
 listfam
 messmajofam
  majovois
 listvois
 messmajovois
 sizeBiggestCluster
 bigClusterOccShannon
 allPatchesOccShannon
 occ1
 occ2
 occ3
 occ4
 occ5
 occ6
 os-data]

patches-own 
  [OS                                                                                       ; type 1, Type 2, type 3
  occurence
  cluster
  ]                                                                              ; fréquence de retour de culture

Breed 
  [agriculteurs agriculteur]

agriculteurs-own 
  [Mon-exploitation
  famille
  OSvoisin
  OSfamille
  ]                                                                                 ; de 0 à 4

                                                                                              ; reseau
;******************************************************************************************
;      INITIALISATION
;******************************************************************************************

to setup
  ca
  ask patches 
   [
   sprout-agriculteurs 1 [set shape "person" set size 0.3]
   ]
  setup-parcelles
  setup-land
  setup-famille
  ;;;;compter les indices à l'initialisation
  MapOS
  calculH
end

;;;;;;;;;;;GIS
to import-ascii-map
ca
 set os-data gis:load-dataset "mondeOS2.asc"
os-In-patches  
end

to OS-In-patches
     gis:apply-raster os-data os
 ask patches
[if  OS = 1 [set pcolor yellow]
if  OS = 2 [set pcolor green]
if  OS = 3 [set pcolor brown]]
end



to setup-aleaOS-regularOcc
  ca
  ask patches 
   [
   sprout-agriculteurs 1 [set shape "person" set size 0.3]
   ]
  setup-parcelles
  setup-land-aleaOS-regularOcc
  setup-famille
  ;;;;compter les indices à l'initialisation
  MapOS
  calculH
end

to setup-regularOS-aleaOcc
  ca
  ask patches 
   [
   sprout-agriculteurs 1 [set shape "person" set size 0.3]
   ]
  setup-parcelles
  setup-land-regularOS-aleaOcc
  setup-famille
  ;;;;compter les indices à l'initialisation
  MapOS
  calculH
end

to setup-regularOS-regularOcc
  ca
  ask patches 
   [
   sprout-agriculteurs 1 [set shape "person" set size 0.3]
   ]
  setup-parcelles
  setup-land-regularOS-regularOcc
  setup-famille
  ;;;;compter les indices à l'initialisation
  MapOS
  calculH
end


to setup-parcelles
  ask agriculteurs
    [
    set Mon-exploitation patch-here 
    ]
end


to setup-land
  ask patches
    [   
    set cluster nobody                                                             ;;appartient à aucun cluster au départ
    let tiralea random-float 100    
    ifelse tiralea < %_of_LU1 
      [set OS 1
      ]
      [ifelse tiralea < ( %_of_LU1 + %_of_LU2 ) 
        [set OS 2 
        ]
        [set OS 3
        ]
    ]    
    update-color
    ] 
ask patches
     [
     set occurence 1 + random Nb_of_max_occurence_of_LU
     ]
end

to setup-land-aleaOS-regularOcc
  ask patches
    [   
    set cluster nobody                                                             ;;appartient à aucun cluster au départ
    let tiralea random-float 100    
    ifelse tiralea < %_of_LU1 
      [set OS 1
      ]
      [ifelse tiralea < ( %_of_LU1 + %_of_LU2 ) 
        [set OS 2 
        ]
        [set OS 3
        ]
    ]    
    update-color
    ] 
ask patches
     [
     set occurence 1
     ]
end

to setup-land-regularOS-aleaOcc
  ask patches
    [   
    set cluster nobody                                                             ;;appartient à aucun cluster au départ
    ifelse pxcor < 9 
      [set OS 1
      ]
      [ifelse pxcor < 17 
        [set OS 2 
        ]
        [set OS 3
        ]
    ]    
    update-color
    ] 
ask patches
     [
     set occurence 1 + random Nb_of_max_occurence_of_LU
     ]
end

to setup-land-regularOS-regularOcc
  ask patches
    [   
    set cluster nobody                                                             ;;appartient à aucun cluster au départ
    ifelse pxcor < 9 
      [set OS 1
      ]
      [ifelse pxcor < 17 
        [set OS 2 
        ]
        [set OS 3
        ]
    ]    
    update-color
    ] 
ask patches
     [
     set occurence 1 
     ]
end

to update-color
  ifelse OS = 1 [set pcolor yellow]
  [ifelse OS = 2 [set pcolor green][set pcolor brown]]
end

to setup-famille
  ask agriculteurs
    [
    set famille random nb_of_social_networks
    set color (62 + 2 * famille) ; couleur en fonction de l'ID famille
    ]
end

;******************************************************************************************
;      GO
;******************************************************************************************

to go
  countOSmin
  countOSvoisin
  countOSfamille
  ask agriculteurs [choisir_occup_sol]
  tick
  if ticks > iteration [stop]
  mapOS
  CalculH
  calculTpsMoyen
  calculShannon
  graphmessage
  
  find-theBiggestCluster
  mapBiggestCluster
end





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;procedure DECISION AGRIC / OS;;;;;;;;;;;;

to choisir_occup_sol

let occ [occurence] of mon-exploitation                                                ; appelle "occ" variable d'occurence de chaque exploitation
let list_possible (list 1 2 3)                                                         ; creation d'une liste des possible qui prend les valeurs 1, 2 et 3
  if occ > Nb_of_max_occurence_of_LU                                                                      ; si l'occurence est superieure à l'occurenc max,
  [set list_possible remove OS list_possible]                                           ; alors on enlève la valeur de l'OS actuelle de l'exploitation de la liste des OS possible

let list_recom (list OSmin OSvoisin OSfamille)                                          ; creation d'une liste de recommandation qui contient les OS recommandé par chaque réseau
let D length filter [? = 1] list_recom                                                  ; creation d'une variable intermediaire D qui contient le nombre de fois ou OS=1 est present 
let F length filter [? = 2] list_recom                                                        ; dans la liste des recommandations 
let G length filter [? = 3] list_recom

let recommand 0                                                                          ; creation d'une nouvelle variable qui prend la valeur 0
ifelse (D = 1 and F = 1) or (F = 1 and G = 1) or (D = 1 and G = 1) or (D = 0 and F = 0 and G = 0)     ; si absence de valeur d'OS majoritaire
  [set recommand 0]                                                                                  ; il n'y a pas de recommandation
  [let lOS_la_plus_recom (list D F G)                                                                  ;sinon creation d'une nouvelle liste qui contient le nombre de recommandation de chaque OS
    set recommand position (max lOS_la_plus_recom) lOS_la_plus_recom + 1]                       ;la valeur recommandée correspond à la position (0, 1, 2) dans la liste qui a la valeur maximale, auquel on ajoute 1 pour avoir des valeurs d'OS égale à 1, 2 ou 3

ifelse member? recommand list_possible                                                ;Si la valeur de recommand fait partie de la liste des possibles
   [ifelse recommand = OS                                                                 ;Si la valeur recommandé est égale à l'OS actuellement pratiqué                                        
       [ ask patch-here [set occurence occ + 1]] ; [occurence] of patch-here occ + 1]                                            ; l'occurence a un "an" de plus
       [ask mon-exploitation [set OS recommand] ;set [OS] of mon-exploitation recommand                                            ;Defini l'OS comme etant la valeur recommandé
       ask patch-here [set occurence 1] ] ;set [occurence] of patch-here 1]                                                  ; sinon on reinitialise l'occurence à 1
   ]
  [ifelse recommand = 0                                                                  ; si recommand ne fait pas partie des possibilités et si recommand = 0
    [let list_com sentence list_possible list_recom                                      ;  création d'une liste commune = liste des possible + liste des recommandations
    Set list_com remove 0 list_com                                                       ; enlever les "0" de cette liste commune
    let list_int modes list_com                                                          ; création de la list_int (une variable temporaire) qui prend la valeur la plus citée de la liste commune
      ifelse occ > Nb_of_max_occurence_of_LU                                                              ; si occurence du patch >= a Nb_of_max_occurence_of_LU
      [ask mon-exploitation [set OS one-of list_int]    ;set [OS] of mon-exploitation one-of list_int                                      ; OS devient la valeur de list_int
        ask patch-here [set occurence 1]]         ;set [occurence] of patch-here 1]                                                   ; l'occurence est ré initialisée à 1
      [ask patch-here [set occurence occ + 1]]]  ;set [occurence] of patch-here occ + 1]]                                           ; sinon OS reste le même et occurence prend un "an" de plus
    [ask mon-exploitation [set OS one-of list_possible]   ;set [OS] of mon-exploitation one-of list_possible                                   ; si recommand est différent de 0 et recommand n'est pas dans la liste des possibles cad à cause de l'occurence
    ask patch-here [set occurence 1]]; set [occurence] of patch-here 1]                                                     ; alors choisit un OS au hasard parmis les 2 autres possibilités
   ]
update-color

end
  


;******************************************************************************************
;      DFN Occupation Sol MINORITAIRE (OSmin)
;******************************************************************************************

to countOSmin                                                              ; on cherche l'OS minoritaire qui sera envoyée par la politique publique (PP)
   ifelse Global_network                                                           ; pour le switch réseau ON/OFF
   [
    let a count patches with [OS = 1]                                      ; création d'une variable avec le nombre de patch OS = 1                
    let b count patches with [OS = 2]
    let c count patches with [OS = 3]
    let list_ddaf (list a b c)                                              ; création d'une liste qui contient le nombre de patch par OS
    ifelse a != b and b != c and a != c                                     ; si tous les 3 sont différents
     [set OSmin position (min list_ddaf) list_ddaf + 1]                     ; alors l'OSmin correpond à la position la plus petite dans la liste +1
     [if a = b and a < c                                                    ; s'il y a deux OS minimum
     [set OSmin random 2 + 1]                                               ; alors on choisit une des deux OS minimum au hasard
     if b = c and b < a                                   
     [set OSmin random 2 + 2]
     if a = c and a < b
     [let list_int (list 1 3)                                               ; idem mais on crée une liste pour effectuer le choix
     set OSmin one-of list_int]]
     ]
    [ set OSmin 0]
end


;******************************************************************************************
;      CALCUL OS VOISINAGE (OSvoisin)
;******************************************************************************************

to countOSvoisin
  set listvois (list )
  ask agriculteurs                                                                        ; on demande a chaque agriculteur
   [ifelse Local_network                                                                       ; bouton switch on/off de l'interface
    [
    let A count neighbors with [OS = 1]                                                    ; A est le nombre de voisin avec OS=1
    let B count neighbors with [OS = 2]                                                     ; B est le nombre de voisin avec OS=2
    let C count neighbors with [OS = 3]                                                     ; C est le nombre de voisin avec OS=3
    let valeur_majo (list A B C)                                                           ; on cree une liste avec le nombre de voisin qui font chaque OS
    let valeur_max max valeur_majo                                                               ; on identifie quel est la valeur max
      ifelse A != B and B != C and A != C [set OSvoisin position (valeur_max) valeur_majo + 1]    ;Si A est different de B diffent de C, OS voisin est la valeur max
        [ifelse A = valeur_max and B != valeur_max and C != valeur_max                    ;si A est egale a la valeur max et B et C sont differents de valeur max
          [set OSvoisin 1]                                                                ; alors OS voisin egal 1    
            [ifelse B = valeur_max and A != valeur_max and C != valeur_max                ;;si B est egale a la valeur max et A et C sont differents de valeur max
              [set OSvoisin 2]                                                             ; alors OS voisin egal 2
                [ifelse C = valeur_max and B != valeur_max and A != valeur_max            ;;;si C est egale a la valeur max et A et B sont differents de valeur max
                  [set OSvoisin 3]                                                        ; alors OS voisin egal 3
                  [set OSvoisin 0]                          ;sinon cela veut dire qu'il y a deux valeurs max egale (A et B par exemple) et une plus faible, dans ce cas pas de message
        ]
        ]
        ]
        ]
        [set OSvoisin 0]                                                         ; pour le switch réseau ON/OFF
 set listvois lput OSvoisin listvois
]
set majovois modes listvois
ifelse length majovois = 1  
[ifelse length (filter [? = first majovois] majovois) > 0.5 * length majovois 
[set messmajovois first majovois]
[set messmajovois 0]]
[set messmajovois 0]
 
 
  end

    
 

;******************************************************************************************
;      CALCUL OS FAMILLE (OSfamille)
;******************************************************************************************

to countOSfamille
set listfam (list )
  ask agriculteurs
   [ifelse Social_network [                                                                      ; pour le switch réseau ON/OFF
    let X count turtles with [famille = [famille] of myself and OS = 1]                     ; on compte le  nombre d'agent qui sont de la meme famille et qui font la meme OS
    let Y count turtles with [famille = [famille] of myself and OS = 2]
    let Z count turtles with [famille = [famille] of myself and OS = 3]
    let majorite_famille (list X Y Z)                                                  ; on cree une liste par famille avec le nombre de membre qui pratique chaque OS
         ifelse X != Y and Y != Z and X != Z                                       ; si X et different de Y et different de Z
         [set OSfamille position (max majorite_famille) majorite_famille + 1]      ; OS famille prend la valeur de l'OS qui est le plus frequent
           [ifelse X = Y and X < Z                                                  ; meme concept que pour OS voisin
           [set OSfamille 3]
           [set OSfamille 0]
           ifelse Y = Z and Y < X 
           [set OSfamille 1]
           [set OSfamille 0]
           ifelse X = Z and X < Y
           [set OSfamille 2]
           [set OSfamille 0]]]
        [set OSfamille 0]

set listfam lput OSfamille listfam
]
set majofam modes listfam
ifelse length majofam = 1  
[ifelse length (filter [? = first majofam] majofam) > 0.5 * length majofam 
[set messmajofam first majofam]
[set messmajofam 0]]
[set messmajofam 0]
  end


;;;;;;;;;;CALCUL DE l'HETEROGENEITE du PAYSAGE;;;;;Issu du modèle de la librairie Netlogo  = patch cluster example

;;1° recherche des cluster;;;;;;;;;;;;;;;;;

to find-clusters
  loop [
    let seed one-of patches with [cluster = nobody]
    if seed = nobody
    [ show-clusters
      stop ]
    ask seed
    [ set cluster self
      grow-cluster ]
  ]
end

to grow-cluster  
  ask neighbors4 with [(cluster = nobody) and
    (pcolor = [pcolor] of myself)]
  [ set cluster [cluster] of myself
    grow-cluster 
   ]
end


to show-clusters
  let counter 0
  loop
  [ let p one-of patches with [plabel = ""]
    if p = nobody
      [ stop ]
    ask p
    [ ask patches with [cluster = [cluster] of myself]
      [ set plabel counter ] ]
    set counter counter + 1 
    ]
end

to find-theBiggestCluster
  let listClusterAttribute (list )                                              ;récupère la liste des numéro de cluster
  ask patches [set listClusterAttribute lput cluster listClusterAttribute]

  let listVluserDom modes listClusterAttribute                                  ; fait le mode de la liste des cluster pour voir s'il y a un cluster domainant
  ifElse (length listVluserDom = 1)                                             ;vérifie qu'il existe un seul cluster le plus grand
  [set sizeBiggestCluster count patches with [cluster = first listVluserDom]    ;calcul de la taille du cluster le plus grand
  let listOccurencePI (list )                                                   
;calcul du shannon de l'occurence des patches du cluster le plus grand
  let counter 1
  while [counter != (Nb_of_max_occurence_of_LU + 1)]
    [set listOccurencePI lput ((count patches with [(cluster = first listVluserDom)  and (occurence = counter)]) / 625) listOccurencePI
     set counter counter + 1]
  set bigClusterOccShannon 0
  foreach listOccurencePI [set bigClusterOccShannon bigClusterOccShannon + ( ? * ln (? + 0.0001)) ]
  set bigClusterOccShannon bigClusterOccShannon * (-1)
  ]
  [set sizeBiggestCluster 0                                                  ;S'il n'existe pas un unique cluster le plus grand, alors donne les valeurs 0 
   set bigClusterOccShannon 0]
  
;calcul du shannon de l'occurence de tout les patchs
 let listOccurencePI (list )
 let counter 1
  while [counter != (Nb_of_max_occurence_of_LU + 1)]
    [set listOccurencePI lput ((count patches with [occurence = counter]) / 625) listOccurencePI
     set counter counter + 1]
  set allPatchesOccShannon 0
  foreach listOccurencePI [set allPatchesOccShannon allPatchesOccShannon + ( ? * ln (? + 0.0001)) ]
  set allPatchesOccShannon allPatchesOccShannon * (-1)
 
 end
  
  
to show-theBiggestCluster
; procedure permettant de faire afficher en rouge le cluster le plus grand, s'il en existe bien un et un seul
let listClusterAttribute (list )
ask patches [set listClusterAttribute lput cluster listClusterAttribute]

let listVluserDom modes listClusterAttribute
if (length listVluserDom = 1)
  [ask patches with [cluster = first listVluserDom] [set pcolor red]]
  
 end
  

;;;;;;;;;;;;;;;;;;;;;;;calcul des indices;;;;;;;;;;;;;;;;

To calculTpsMoyen
 set som1 0
 set moy1 0
 ask patches with [OS = 1]
  [let nbrpOS1 count patches with [OS = 1]
   set som1 som1 + occurence
   set moy1 som1 / nbrpOS1
   set moy1 moy1 * 100
   set moy1 precision moy1 0]       
 ifElse ticks = 1 
   [set listoccOS1 (list moy1)]
   [set listoccOS1 lput moy1 listoccOS1]
 if ticks = iteration 
    [set tpsmoyen1 sum listoccOS1 / iteration / 100]        
 
 set som2 0
 set moy2 0
 ask patches with [OS = 2]
  [let nbrpOS2 count patches with [OS = 2]
   set som2 som2 + occurence
   set moy2 som2 / nbrpOS2
   set moy2 moy2 * 100
   set moy2 precision moy2 0]       
 ifElse ticks = 1 
   [set listoccOS2 (list moy2)]
   [set listoccOS2 lput moy2 listoccOS2]
 if ticks = iteration 
    [set tpsmoyen2 sum listoccOS2 / iteration / 100]        
 
 set som3 0
 set moy3 0
 ask patches with [OS = 3]
  [let nbrpOS3 count patches with [OS = 3]
   set som3 som3 + occurence
   set moy3 som3 / nbrpOS3
   set moy3 moy3 * 100
   set moy3 precision moy3 0]       
 ifElse ticks = 1 
   [set listoccOS3 (list moy3)]
   [set listoccOS3 lput moy3 listoccOS3]
 if ticks = iteration 
    [set tpsmoyen3 sum listoccOS3 / iteration / 100] 
end





;;;;;;2°calcul de l'indice général de l'hétérogéneité à partir du nbre de cluster identifié


to CalculH
 ask patches 
  [set plabel ""
  set cluster nobody]
  find-clusters
  MapH
  
  set Frag (max [plabel] of patches + 1) 
end

to calculShannon
let A (count patches with [os = 1] / 625)
let B (count patches with [os = 2] / 625)
let C (count patches with [os = 3] / 625)
set Ishannon 0
set Ishannon  Ishannon - ((A * ln (A + 0.0001)) + (B * ln (B + 0.0001)) + (C  * ln (C + 0.0001)))
end

;;;;;;;;;;;;;;;;;;;;;;Procedure graphique sur OS"""""""""""""""""""""""""""""

to mapOS
 set-current-plot "MapLU" 
set-current-plot-pen "LU3" 
 plot count patches with [OS = 3] / 625
 
 set-current-plot-pen "LU1"
  plot count patches with [OS = 1] / 625
  
 set-current-plot-pen "LU2"
  plot count patches with [OS = 2] / 625
  
  set-current-plot-pen "I-Shannon"
  plot Ishannon
 
end


;;;;;;;;;;;;;;;;;Procédure graphique sur Indice d'héterogéneité du paysage
 to mapH
  set-current-plot "Landscape Fragmentation"
  set-current-plot-pen "FraG"
 plot FraG
 end
 
 
to graphmessage
  
set-current-plot "Network incentives (1=LU1, 2=LU2, 3=LU3)"
set-current-plot-pen "Global network"
plot OSmin
set-current-plot-pen "Social network"
plot messmajofam
set-current-plot-pen "Local network"
plot messmajovois


end




to mapBiggestCluster
  set-current-plot "Main Cluster Monitoring"
  set-current-plot-pen "Main cluster size"
  plot  sizeBiggestCluster
  set-current-plot-pen "occurences distribution in main cluster"
  plot (bigClusterOccShannon * 100)
  set-current-plot-pen "occurences distribution of all patches"
  plot (allPatchesOccShannon * 100)
end





@#$#@#$#@
GRAPHICS-WINDOW
232
10
596
395
-1
-1
14.16
1
5
1
1
1
0
1
1
1
0
24
0
24
1
1
1
ticks

BUTTON
6
10
72
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
8
166
180
199
%_of_LU3
%_of_LU3
100 - %_of_LU2 - %_of_LU1
100 - %_of_LU2 - %_of_LU1
34
1
1
NIL
HORIZONTAL

SLIDER
7
130
179
163
%_of_LU2
%_of_LU2
0
100 - %_of_LU1
33
1
1
NIL
HORIZONTAL

SLIDER
7
94
179
127
%_of_LU1
%_of_LU1
0
100
33
1
1
NIL
HORIZONTAL

BUTTON
141
10
204
43
Go
GO
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
611
61
827
106
LU incentive from global network
OSmin
17
1
11

PLOT
611
111
1097
292
MapLU
Time
% LU
0.0
1.0
0.0
1.0
true
true
PENS
"LU2" 1.0 0 -10899396 true
"LU1" 1.0 0 -1184463 true
"LU3" 1.0 0 -6459832 true
"I-Shannon" 1.0 0 -16777216 true

PLOT
612
298
1098
475
Landscape Fragmentation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true
"Heterogeneité" 1.0 0 -16777216 true
"FraG" 1.0 0 -16777216 true

SWITCH
16
443
165
476
Social_network
Social_network
0
1
-1000

SWITCH
17
479
164
512
Local_network
Local_network
0
1
-1000

SWITCH
16
407
166
440
Global_network
Global_network
0
1
-1000

SLIDER
8
208
180
241
Nb_of_max_occurence_of_LU
Nb_of_max_occurence_of_LU
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
7
53
179
86
iteration
iteration
0
500
310
5
1
NIL
HORIZONTAL

SLIDER
7
251
180
284
nb_of_social_networks
nb_of_social_networks
3
10
5
1
1
NIL
HORIZONTAL

MONITOR
611
11
715
56
Avg time * 100
moy1
17
1
11

MONITOR
719
10
824
55
Shannon index
Ishannon\n
17
1
11

PLOT
232
406
594
671
Network incentives (1=LU1, 2=LU2, 3=LU3)
NIL
NIL
0.0
10.0
0.0
4.0
true
true
PENS
"Global network" 1.0 0 -16777216 true
"Social network" 1.0 0 -13345367 true
"Local network" 1.0 0 -2064490 true

MONITOR
828
10
945
55
Size main cluster
sizeBiggestCluster
17
1
11

BUTTON
75
10
138
43
Step
GO
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
881
66
1024
99
Show main cluster
show-theBiggestCluster
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
948
10
1094
51
Main Cluster Occ Shannon
bigClusterOccShannon
17
1
10

PLOT
612
481
1099
669
Main Cluster Monitoring
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"Main cluster size" 1.0 0 -16777216 true
"occurences distribution in main cluster" 1.0 0 -2674135 true
"occurences distribution of all patches" 1.0 0 -2064490 true

BUTTON
9
300
130
333
NIL
import-ascii-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
32
384
182
402
Network activation
13
0.0
1

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="60" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>Ishannon</metric>
    <metric>TpsMoyen1</metric>
    <metric>TpsMoyen2</metric>
    <metric>TpsMoyen3</metric>
    <metric>FraG</metric>
  </experiment>
  <experiment name="experimentWorldAleaOSaleaOcc" repetitions="60" runMetricsEveryStep="true">
    <setup>import-world "C:/networld/iriusAleaOSaleaOcc.csv"
random-seed new-seed</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>Ishannon</metric>
    <metric>TpsMoyen1</metric>
    <metric>TpsMoyen2</metric>
    <metric>TpsMoyen3</metric>
    <metric>FraG</metric>
  </experiment>
  <experiment name="experimentWorldAleaOSregularOcc" repetitions="60" runMetricsEveryStep="true">
    <setup>import-world "C:/networld/iriusAleaOSregularOcc.csv"
random-seed new-seed</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>Ishannon</metric>
    <metric>TpsMoyen1</metric>
    <metric>TpsMoyen2</metric>
    <metric>TpsMoyen3</metric>
    <metric>FraG</metric>
  </experiment>
  <experiment name="experimentWorldRegularOSregularOcc" repetitions="60" runMetricsEveryStep="true">
    <setup>import-world "C:/networld/iriusRegularOSregularOcc.csv"
random-seed new-seed</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>Ishannon</metric>
    <metric>TpsMoyen1</metric>
    <metric>TpsMoyen2</metric>
    <metric>TpsMoyen3</metric>
    <metric>FraG</metric>
  </experiment>
  <experiment name="experimentWorldRegularOSaleaOcc" repetitions="60" runMetricsEveryStep="true">
    <setup>import-world "C:/networld/iriusRegularOSaleaOcc.csv"
random-seed new-seed</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>Ishannon</metric>
    <metric>TpsMoyen1</metric>
    <metric>TpsMoyen2</metric>
    <metric>TpsMoyen3</metric>
    <metric>FraG</metric>
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
