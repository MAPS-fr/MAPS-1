extensions [sound]

globals 
;;; Variables globales modifiees lors des itérations (step)
[ exiter
  ;; permet de compter ceux qui sortent de la grille
  NivAppro1 NivAppro2 NivAppro3 NivAppro4
  ;; permet de compter pour chaque niveau le nombre d'agents sortis de la grille - utile pour les plots
]


patches-own 
;;; attributs des patches 
[ land-use ;; 1 = route, 2 = batiment ; précise le type de lieu sur lequel se trouve l'agent (route, bâtiment,...). 
  contamination ;; 0 = no 1 = yes
  direction-nuage ;; pente de la fuite
 ]

turtles-own
;;; attributs des turtles 
[vivant ;; 0 (mort) or 1 (en vie)
 NivAppro  ;; décrit le niveau d'appropriation des procédures, varie de 1 à 4 (statique)
 ;; Ces  "niveaux" correspondent aux cas déterminés en fonction d'un niveau d'appropriation des consignes et d'un niveau d'influençabilité
 ;; Pour un agent donné : le niveau d'appropriation des consignes est fixe, le niveau d'influençabilité sera dynamique dans une version ultérieure du modèle 
 ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Initialisation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  ca ;;;clear all (les variables globales notamment sont à 0)
  setup-patches ;;; initialisation de la grille (routes, bâtiments)
  setup-agents ;;; initialisation des agents
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Run model;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  
;;; bonus "Alarme"... 
if son? and ticks = 0
   [sound:play-sound-and-wait "AlarmeCucaracha.wav"]

;;; en fixant une grande valeur à la variable direction-nuage pour les bâtiments, les agents suivent les routes lorsqu'ils choisissent la fuite.
ask patches with [land-use = 2] 
     [set direction-nuage 500]

;;; dessin des traces des agents
ask turtles
     [ifelse traces-agents?
        [pen-down]
        [pen-up]
     ]
   
;;; COMPORTEMENT DES AGENTS : pour tous les agents en vie et à chaque step, on exécute le "diagramme transition"  
;;; En fonction du "cas" (NivAppro), on exécute le comportement approprié (ChercherBatiment,FuirNuage, SuivreVoisin, SeDeplacerAleatoirement)) 
ask turtles with [vivant = 1] 
     [DiagTransition]
     
;;; COMPORTEMENT DU NUAGE
;;; lorsqu'on lance la simulation, tick s'incrémente et le nuage s'étend.
;;; ticks mod 1 = 0 permettra de régler ultérieurement la vitesse du nuage (en multiple du nombre de ticks (mod x))  
if (ticks > 0) and (ticks mod 1 = 0) 
     [Sepropager]

;;; COMPTAGE, GRAPHIQUE et TRACES
;;; procédure de comptage des morts suivant leurs niveaux d'appropriation
kill-agents
;;; graphique 
if nb-agents > 0
[do-plotting]

     

;;; SORTIE DE GRILLE
;;; Procédure de traitement des agents qui ne sont plus dans la grille :  
;;; on incrémente les compteurs NivAppro1, NivAppro2, NivAppro3, NivAppro4
;;; on les considère comme morts 
SortirGrille


;;; le compteur tick, qui indique le nombre de step, s'incrémente de 1
tick

;;; ARRET DE LA SIMULATION
;;; si tous les patches route sont contaminés, alors la simulation s'arrête (le nuage s'est étendu sur toute la grille)
if count patches with [contamination = 1] = count patches with [land-use = 1 ] [stop]


end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; initialisation de la grille (routes, bâtiments)
to setup-patches
    ask patches
     ;;; on colorie les routes en gris
      [ifelse (pycor mod 6) = 0 ;;routes horizontales : largeur 1 patch
           or (pxcor mod 5) = 0 or ((pxcor - 1) mod 5 = 0)  ;; routes verticales : largeur 2 patches 
           [set land-use 1 set pcolor grey]
   ;;; on colorie les bâtiments (en jaune) là où il n'y a pas de routes
           [set land-use 2  ;; bâtiments
            set pcolor yellow]
       ] 
end

;;; initialisation des agents
to setup-agents
   ;; on place les agents sur les bâtiments
  placer_agents_interieur
  ;;; on place les agents sur les routes
  placer_agents_exterieur
  ;;; on définit les attributs des agents (des cercles noirs, un niveau d'appropriation)
  AffecterAttributsAgents   
end

;;; Placer les agents à l'interieur  
to placer_agents_interieur
;;; on place les agents sur les bâtiments 
;;; On réitère le processus autant de fois qu'il y a d'agents à l'intérieur ((ie jusqu'au plafond ceiling en fonction de la variable percent*inside)
repeat ceiling (nb-agents * percent-inside / 100) ;; agents situés à l'intérieur
[ask n-of 1 patches with [land-use = 2]
;;; sprout 1 : on crèe 1 agent à l'intérieur (with land-use = 2)
    [sprout 1] 
]
end  


;;; Placer les agents à l'exterieur
to placer_agents_exterieur
;;; on place les agents sur les routes 
;;; On réitère le processus autant de fois qu'il y a d'agents à l'extérieur (ie jusqu'au plafond ceiling en fonction de la variable percent*inside)
repeat ceiling (nb-agents * (100 - percent-inside) / 100) ;; agents situés à l'extérieur
[
ask n-of 1 patches with [land-use = 1]
;;; sprout 1 : on crèe 1 agent à l'extérieur (with land-use = 1)
    [sprout 1]
]
end

;;; Definir les attributs des agents
to  AffecterAttributsAgents
;;; on définit les attributs des agents situés à l'extérieur (des cercles noirs vivants avec un tx d'appro)
set-default-shape turtles "circle"   
ask turtles
     [set vivant 1
      ;;; tous les agents sont vivants en début de simulation
      set color black
      set size 0.5
      AffecterAppropriation]
end

;;; Definir le taux d'appropriation
to AffecterAppropriation
  ;;; en fonction de la distribution que l'on choisit (Gauss, Uniforme ou Poisson), on renseigne NivAppro de 1 à 4 
 ifelse Fonction_Niveau_Appropriation = "Gaussien" [
    ;;; il s'agit d'une distribution gaussienne avec une moyenne de 2.5 (nivappro va de 1 à 4) et un écart-type de 1
 let  a round random-normal 2.5 1
 ifelse a < 1 
   [set NivAppro 1] [
 ifelse a > 4 
   [set NivAppro 4 ] [
    set NivAppro a]
 ]] [ 
  ifelse Fonction_Niveau_Appropriation = "Uniforme" [
     ;;; il s'agit d'une distribution normale renvoyant aléatoirement un entier compris entre 0 et 5
    let  a round random 4 + 1
    set NivAppro a]
    [ 
 ifelse Fonction_Niveau_Appropriation = "Poisson" [
   ;;; il s'agit d'une loi de poisson avec une moyenne de 2.5 (Nivappro va de 1 à 4) 
 let a random-poisson 2.5 
 ifelse a < 1 
   [set NivAppro 1] [
 ifelse a > 4 
   [set NivAppro 4 ] [
    set NivAppro a]
 ]] []
 ]] 
 
end 


;;; Définir le comportement des agents (DIAGRAMME DE TRANSITION) 
to DiagTransition
 ifelse NivAppro = 1
  [ifelse land-use = 2
    [stop]
    [ChercherBatiment]
  ] [
 ifelse NivAppro = 2
  [ifelse (random 100) < 30 
    [FuirNuage]
    [ifelse land-use = 1 
      [ChercherBatiment]
      [stop]
    ]
  ] [
 ifelse NivAppro = 3
  [let a (random 5)
    ifelse a = 0 [ChercherBatiment] [
    ifelse a = 1 [FuirNuage] [
    ifelse a = 2 [stop] [
    ifelse a = 3 [SuivreVoisin] [
    ifelse a = 4 [SeDeplacerAleatoirement] [
    ]]]]]] [  
 ifelse NivAppro = 4
   [ifelse count turtles in-radius 10 = 0
     [let a (random 4)
      ifelse a = 0 [ChercherBatiment] [
      ifelse a = 1 [FuirNuage] [
      ifelse a = 2 [SeDeplacerAleatoirement] [
      ifelse a = 3 [stop] [
      ]]]]]
     [SuivreVoisin] ] ;;; consiste a recuperer la direction d'un voisin proche
     []
   ]]] 
end


;;;Chercher un batiment
to ChercherBatiment ;;je cherche le bâtiment le plus proche, je m'oriente et je m'avance vers lui d'un patch 
    ifelse land-use != 2 
     [let a [pxcor] of min-one-of patches in-radius 3 with [land-use = 2] [distance myself]
      let b [pycor] of min-one-of patches in-radius 3 with [land-use = 2] [distance myself]
      set heading acos ((xcor - a) / sqrt ((xcor - a)^ 2 + (ycor - b)^ 2))
        fd 1 ] ;;; forward 1
      [stop]
   
end

;;;Suivre un voisin proche (dans un rayon de 10 patches)
to SuivreVoisin
   ;;; on choisit un voisin dans un rayon de 10 patches
  let a one-of turtles in-radius 10
  ;;; on prend la direction de ce voisin
  set heading [heading] of a
  ;;; on avance d'un patch
  fd 1  ;;; forward 1
end

;;;FuirNuage
to FuirNuage
  downhill direction-nuage
end

;;; Se déplacer aléatoirement
to SeDeplacerAleatoirement
  ;;; l'agent se déplace d'un patch dans une direction aléatoire comprise entre 0 et 360°
  set heading random 360 fd 1
end



;;;Le nuage se propage
to Sepropager
  ;;; Chaque patch contaminé étend sa contamination sur les patchs voisins non contaminés situés sur les routes ; 
  ;;; Chaque patch contaminé devient rose
  ask patches with [contamination = 1]
           [ask neighbors with [land-use = 1 and contamination = 0]
                [set contamination 1 set pcolor pink]
           ]
        
end



;;;Traiter le cas des agents qui sortent de la grille
to SortirGrille
  ask turtles [if xcor = max-pxcor or xcor = min-pxcor or ycor = max-pycor or ycor = min-pycor 
              [ set exiter exiter + 1
                ;;; on compte les agents qui sortent de la grille
                             
             ifelse NivAppro = 1 [
               set NivAppro1 NivAppro1 + 1] [
             ifelse NivAppro = 2 [
               set NivAppro2 NivAppro2 + 1] [
               ifelse NivAppro = 3 [
             set NivAppro3 NivAppro3 + 1] [        
              ifelse NivAppro = 4 [
             set NivAppro4 NivAppro4 + 1] []]]]                  
                   die]]
            
end

;;;Compter les morts
to Kill-agents
;;; procédure de comptage des morts - les agents contaminés sont morts
ask patches with [contamination = 1]
    [ask turtles-here
      [set vivant 0
       set color red]]        
end
    

;;;Faire des graphiques (plots)
to do-plotting
set-current-plot "% d'agents..."
  set-current-plot-pen "morts"
  plotxy (ticks) (count turtles with [vivant = 0] / nb-agents * 100)
  
  set-current-plot-pen "vivants à l'intérieur"
  plotxy (ticks) ((count turtles-on patches with [land-use = 2])/ nb-agents * 100)

  
  set-current-plot-pen "vivants à l'extérieur"
 plotxy (ticks) ((count turtles-on patches with [land-use = 1] - count turtles with [vivant = 0] ) / nb-agents * 100)

 set-current-plot-pen "vivants hors grille"
 plotxy (ticks) (exiter / nb-agents * 100)
end

to do-plotting-Appropriation
 set-current-plot "Répartition des niveaux d'appropriation"
 set-current-plot-pen "Niveau d'appropriation"  
 clear-plot
 plotxy 1 (count turtles with [NivAppro >= 1 and NivAppro < 2] / nb-agents * 100 ) 
 plotxy 2 (count turtles with [NivAppro >= 2 and NivAppro < 3] / nb-agents * 100 ) 
 plotxy 3 (count turtles with [NivAppro >= 3 and NivAppro < 4] / nb-agents * 100 ) 
 plotxy 4 (count turtles with [NivAppro >= 4 ] / nb-agents * 100 ) 
end



to do-plotting-Appropriation-fin
set-current-plot "Répartition des sauvés dans la population"
  set-current-plot-pen "Niveau d'appropriation"  
  clear-plot
  plotxy 1 ((count turtles with [nivappro = 1 and vivant = 1] + NivAppro1)  / nb-agents * 100 ) 
  plotxy 2 ((count turtles with [nivappro = 2 and vivant = 1] + NivAppro2) / nb-agents * 100 ) 
  plotxy 3 ((count turtles with [nivappro = 3 and vivant = 1] + NivAppro3) / nb-agents * 100 ) 
  plotxy 4 ((count turtles with [nivappro = 4 and vivant = 1] + NivAppro4) / nb-agents * 100 )   
end
@#$#@#$#@
GRAPHICS-WINDOW
264
14
728
499
-1
-1
4.6804124
1
2
1
1
1
0
0
0
1
0
96
0
96
0
0
1
ticks

BUTTON
198
14
261
47
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

SLIDER
4
53
176
86
nb-agents
nb-agents
0
2000
1000
100
1
NIL
HORIZONTAL

SLIDER
5
95
177
128
percent-inside
percent-inside
0
100
35
1
1
NIL
HORIZONTAL

BUTTON
198
94
261
127
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

BUTTON
198
53
261
86
Cloud
if mouse-down?   \n     [ask patch mouse-xcor mouse-ycor\n      [set contamination 1 \n       set pcolor red \n     ;;; l'endroit cliqué, point de depart du nuage est rouge et contaminé\n       set direction-nuage 100000]\n     ]\nrepeat world-height \n     [diffuse direction-nuage 1]\n\n     \n\n\n     \n \n \n 
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
731
103
1012
277
% d'agents...
Time
%
0.0
10.0
0.0
100.0
true
true
PENS
"morts" 1.0 0 -2674135 true
"vivants à l'intérieur" 1.0 0 -1184463 true
"vivants à l'extérieur" 1.0 0 -7500403 true
"vivants hors grille" 1.0 0 -10899396 true

CHOOSER
3
133
201
178
Fonction_Niveau_Appropriation
Fonction_Niveau_Appropriation
"Gaussien" "Uniforme" "Poisson"
1

PLOT
4
183
261
364
Répartition des niveaux d'appropriation
Niveau d'appropriation
Fréquence
1.0
4.0
0.0
50.0
true
false
PENS
"default" 1.0 1 -16777216 true
"Niveau d'appropriation" 1.0 0 -6459832 true

MONITOR
733
14
888
59
vivants (sur et hors grille)
count turtles with [vivant = 1] + exiter
0
1
11

BUTTON
163
203
257
236
Distribution
do-plotting-appropriation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
733
58
806
103
morts
count turtles with [vivant = 0]
0
1
11

TEXTBOX
10
10
109
52
****************\n Paramètres entrée\n****************
11
0.0
1

SWITCH
110
384
249
417
traces-agents?
traces-agents?
1
1
-1000

PLOT
730
279
995
476
Répartition des sauvés dans la population
Niveau d'appropriation
%
1.0
4.0
0.0
50.0
true
false
PENS
"Niveau d'appropriation" 1.0 1 -16777216 true

BUTTON
732
483
890
516
et les gagnants sont...
do-plotting-appropriation-fin
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
887
14
1033
59
Vivants sortis de la grille
exiter
17
1
11

MONITOR
11
437
82
482
NIL
NivAppro1
17
1
11

MONITOR
84
438
155
483
NIL
NivAppro2
17
1
11

MONITOR
154
438
225
483
NIL
NivAppro3
17
1
11

MONITOR
11
483
82
528
NIL
NivAppro4
17
1
11

SWITCH
2
383
105
416
son?
son?
1
1
-1000

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1RC2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
