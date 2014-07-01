;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definition des variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals
[
listmarches  ; liste contenant l'identifiant de chaque marche
jours  ; Nombre de jours ecoules
nb-villageois-au-marche-total   ; Nombre total de villageois arrives a un marche
nb-villageois-total-jours  ; Nombre de villageois crees au cours de la simulation (= jours * nb-villageois)
]

breed [taxis taxi]
breed [stations station] ; Stations et marches sur lesquels convergent les villageois
breed [villageois villageoi]


taxis-own
[
noeud-actuel  ; Station sur laquelle se situe le taxi a l'instant t
noeud-suivant  ; Prochaine station (t+1) desservie par le taxi
etat   ; Variable permettant d'organiser et de declencher des procedures en fonction du contexte : 0 choix-noeud-suivant , 1 charge-passagers , 2 decharge-passagers , 3 avance
nb-clients-embarques  ; Nombre de clients dans le taxi a l'instant t         
clients-choisis  ; Nombre de villageois ayant la m�me destination que le taxi et a embarquer a l'instant t+1
mes-clients  ; Nombre de clients dans le taxi a l'instant t
destination-marche-taxis  ; Marche choisi comme destination par le taxi
nb-noeuds-passes  ; Compteur indiquant le nombre de marches desservis au cours de la simulation
nb-noeuds-chargement  ; Compteur indiquant le nombre de marches sur lesquels le taxi a embarque des clients
efficacite  ; Indice d'efficacite du taxi : nb-noeuds-chargement / nb-noeuds-passes. ex: un indice proche de 0 signifie que le taxi a maximiser le nombre de clients pour une distance parcourue minimale
]

stations-own
[
marche? ; Attribut permettant d'indiquer si la station est un marche ou non (0=village et 1=marche)
potentiel-brut  ; Nombre de villageois situes dans l'aire d'attraction de la station
potentiel-net  ; Indice de potentiel d'atractivite d'une station : potentiel-brut / maxpotentiel (nombre de villageois de la station la plus atractive)
nb-villageois-station  ; Nombre de villageois situes sur une station a l'instant t
nb-villageois-pris  ; Total des clients pris pour chaque station au cours de la simulation
nb-villageois-au-marche  ; Total des clients arrives a un marche
]

villageois-own 
[ 
destination-marche  ; Destination du villageoi (correspondant a un des marches)
destination-noeud  ; Station attirant le villageoi a son initialisation
taxi?  ; Variable d'etat permetant d'indiquer si le villageoi et dans un taxi (1) ou non (0)
]

links-own 
[
traffic-brut  ; Nombre de fois ou le taxi est passe sur un axe
traffic-net  ; idem mais normalise
]



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialisation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to initialisation
  ca
  creer-villageois
  creer-stations-marches
  connecter-stations
  choix-villageois-stations-marches    
  creer-taxis
  setup-plot
end

to creer-villageois ; Creer un nombre de villageois grace a un slider r�partis al�atoirement dans l'espace
  create-villageois nb-villageois 
  set nb-villageois-total-jours nb-villageois-total-jours + nb-villageois 
  ask villageois 
  [
    set color 36
    set shape "person"
    set size 0.8
    set xcor random-float max-pxcor
    set ycor random-float max-pycor
  ]
end

to estimer-potentiel-stations ; Definir l'attractivite de chaque station a l'initialisation
  ask stations 
  [ 
    set potentiel-brut count villageois with [distance myself <= rayon-attraction-stations] ] 
    let maxpotentiel max [potentiel-brut] of stations 
    ask stations 
  [
    set potentiel-net potentiel-brut / maxpotentiel 
    set size 1 + potentiel-net ^ 2 
  ]
end

to mise-a-jour-potentiel-stations  ; Mise a jour de l'attractivite des stations au cours de la simulation
  let maxpotentiel max [potentiel-brut] of stations
  ask stations 
  [
    set potentiel-net potentiel-brut / maxpotentiel 
    set size 1 + potentiel-net ^ 2
  ]
end

to mise-a-jour-traffic-liens  ; Mise a jour de l'attractivite des liens au cours de la simulation
  let maxtraffic max [traffic-brut] of links
  ask links 
  [
    set traffic-net traffic-brut / maxtraffic 
  ]
end

to creer-stations-marches ; Creer un nombre de stations et de marches grace a des sliders
  create-stations nb-stations 
  [
    setxy random-xcor random-ycor 
    set color green 
    set shape "flag" 
    set size 1 
  ]
  ask n-of nbmarches stations 
  [
    set marche? 1 
    set color red 
    set shape "house" 
  ]
  set listmarches [who] of stations with [ marche? = 1] 
  estimer-potentiel-stations
end

to connecter-stations ; Creer le reseau (liens entre les stations) en fonction d'une distance choisie par l'utilisateur (slider "contrainte-distance")
  ask stations 
  [
    create-links-with stations in-radius contrainte-distance with [who != [who] of myself] 
      [
        set color 9 
        set thickness 0.02 
      ]
  ]
end
        
to creer-taxis  ; Creer des taxis (grace a un slider) se situant aleatoirement sur des stations
  create-taxis nb-taxis
  [
    set noeud-actuel one-of stations 
    move-to noeud-actuel
    set noeud-suivant one-of [link-neighbors] of noeud-actuel 
    set nb-noeuds-passes (nb-noeuds-passes + 1) 
    let ns noeud-suivant 
    ask noeud-actuel 
    [set [traffic-brut] of link-with ns [traffic-brut] of link-with ns + 1] 
    set shape "car" 
    set size 2 
    set color yellow 
    set etat 1 
    set mes-clients [] 
    set clients-choisis [] 
  ]
end

to choix-villageois-stations-marches  ; Definir la destination de la station et du marche de chaque villageoi en fonction du potentiel de chacun
  ask villageois  
  [    
    set destination-noeud max-one-of stations [ potentiel-brut / (distance myself) ] 
    set destination-marche max-one-of stations with [ marche? = 1 ] [ potentiel-brut / (distance myself) ] 
  ]  
end
  
to compte-voyageurs ; Compter le nombre de voyageurs a chaque station
  ask stations 
  [
    set nb-villageois-station count villageois-here
  ]
end
 
 
 
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Simulation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
to go
  if ticks = (jours * nb-ticks-jours)
  [
    creer-villageois
    mise-a-jour-potentiel-stations
    choix-villageois-stations-marches
    set jours (jours + 1)  
  ]
  deplacer-villageois
  compte-voyageurs
  go-taxis
  do-plotting
  cartographie-traffic
  mise-a-jour-traffic-liens
  tick
end
 
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Villageois
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to deplacer-villageois ; Deplacer les villageois vers une station
  ask villageois with [taxi? = 0] 
  [
    face destination-noeud 
    ifelse distance destination-noeud >= vitesse-deplacement 
    [ fd vitesse-deplacement ] 
    [ if distance destination-noeud > 0 [ move-to destination-noeud ] ] 
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Taxis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go-taxis  ; Sequence des procedures des taxis
  ask taxis
  [
    ifelse etat = 0 
      [choix-noeud]
      [ifelse etat = 1
        [charger-clients]
        [ifelse etat = 2
          [decharger-clients]
          [deplacer]
        ]
      ]
  ]
end

to choix-noeud  ; Choisir le prochain noeud sur lequel va passer le taxi
  ifelse destination-marche-taxis = 0 
    [
      set noeud-actuel noeud-suivant 
;      ifelse Taxi_Opportuniste?   
;      [set noeud-suivant max-one-of [link-neighbors with [any? villageois-here with [taxi? = 0]]] of noeud-actuel [potentiel-net]] 
      set noeud-suivant one-of [link-neighbors] of noeud-actuel 
      let ns noeud-suivant 
      ask noeud-actuel 
      [set [traffic-brut] of link-with ns [traffic-brut] of link-with ns + 1] 
      set etat 1 
    ]
    [ 
      let dest destination-marche-taxis 
      set noeud-actuel noeud-suivant 
      set noeud-suivant min-one-of [link-neighbors] of noeud-actuel [distance dest] 
      let ns noeud-suivant 
      ask noeud-actuel 
      [set [traffic-brut] of link-with ns [traffic-brut] of link-with ns + 1] 
      ifelse (capacite-max-taxis > nb-clients-embarques) 
        [set etat 1] 
        [set etat 4] 
    ] 
  set nb-noeuds-passes (nb-noeuds-passes + 1) 
end
 
to charger-clients  ; Choisir les clients et les embarquer
  ifelse any? villageois-here with [taxi? = 0]
    [
      let nb-clients-ici [nb-villageois-station] of noeud-actuel 
      if nb-clients-embarques = 0 
      [ set destination-marche-taxis [destination-marche] of one-of villageois-here with [taxi? = 0] ] 
      let dest-taxi destination-marche-taxis 
      let nb-clients-possibles count villageois-here with [taxi? = 0 and destination-marche = dest-taxi] 
      if nb-clients-possibles > 0 
      [
        let nb-clients-a-prendre min (list (capacite-max-taxis - nb-clients-embarques) nb-clients-possibles) 
        set [nb-villageois-pris] of noeud-actuel [nb-villageois-pris] of noeud-actuel + nb-clients-a-prendre 
        set [potentiel-brut] of noeud-actuel [potentiel-brut] of noeud-actuel + nb-clients-a-prendre 
        set clients-choisis n-of nb-clients-a-prendre villageois-here with [taxi? = 0 and destination-marche = dest-taxi ] 
        ask clients-choisis 
        [ 
          set taxi? [who] of myself  
          set color red 
        ]
        set mes-clients fput clients-choisis mes-clients 
        set nb-clients-embarques count villageois with [taxi? = [who] of myself ] 
        set nb-noeuds-chargement (nb-noeuds-chargement + 1) 
        set efficacite nb-noeuds-chargement / nb-noeuds-passes 
      ]    
      set etat 3 
    ]
    [
      set etat 3 
    ]
end

 
to decharger-clients  ; Decharger les clients et mettre a jour les compteurs
  let n nb-clients-embarques 
  ask destination-marche-taxis 
    [
    set nb-villageois-au-marche nb-villageois-au-marche + n 
    set nb-villageois-au-marche-total nb-villageois-au-marche-total + n 
    ]
  set nb-clients-embarques 0 
  set mes-clients [] 
  set clients-choisis [] 
  ask villageois with [taxi? = [who] of myself] 
  [die]
  set destination-marche-taxis 0 
  set etat 0 
  ask taxis [set color yellow] 
end
 

to deplacer  ; Deplacer le taxi, avec une optimisation faite en fonction de la distance au marche
  set heading towards noeud-suivant
  if length mes-clients > 0 [ask villageois with [taxi? = [who] of myself] [set heading [heading] of myself]]  ; a ameliorer
  ifelse distance noeud-suivant > vitesse-deplacement * facteur-vitesse + 0.1
  [
    fd vitesse-deplacement * facteur-vitesse
    if length mes-clients > 0 [ask villageois with [taxi? = [who] of myself] [fd vitesse-deplacement * facteur-vitesse]]
  ]
  [
    ifelse noeud-suivant = destination-marche-taxis
      [ set etat 2 ]
      [
        if length mes-clients > 0 [ask villageois with [taxi? = [who] of myself]  [move-to [noeud-suivant] of myself]]
        set etat 0
      ]  
  ] 
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Graphiques
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to cartographie-traffic  ; Trace des trajets en fonction du traffic
  ask links with [traffic-brut > 1] [set thickness 0.02 + traffic-net / 2]
end

to setup-plot ; Histogramme montrant l'efficacite des taxis
  set-current-plot "efficacite"
  set-histogram-num-bars count taxis
end

to do-plotting  ; Tracer le graphique du nombre de clients deposes sur chaque marche
  set-current-plot "Nb villageois arrives"
  ask station first listmarches 
    [
    set-current-plot-pen "marche1" plot nb-villageois-au-marche
    set label "Marche 1"
    ]
  if nbmarches > 1 
    [
    ask station item 1 listmarches 
      [
      set-current-plot-pen "marche2" plot nb-villageois-au-marche
      set label "Marche 2"
      ]
    ]
  if nbmarches > 2 
    [
    ask station item 2 listmarches 
      [
      set-current-plot-pen "marche3" plot nb-villageois-au-marche
      set label "Marche 3"
      ]
    ]
  set-current-plot "efficacite"
  histogram [efficacite] of taxis  
end

@#$#@#$#@
GRAPHICS-WINDOW
188
10
736
579
-1
-1
16.30303030303031
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
32
0
32
1
1
1
ticks

CC-WINDOW
5
608
1128
703
Command Center
0

SLIDER
7
131
172
164
nb-stations
nb-stations
0
100
63
1
1
NIL
HORIZONTAL

SLIDER
5
177
177
210
rayon-attraction-stations
rayon-attraction-stations
1
30
18
1
1
NIL
HORIZONTAL

BUTTON
4
10
79
43
NIL
initialisation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
5
46
60
79
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

SLIDER
3
381
173
414
vitesse-deplacement
vitesse-deplacement
0
0.1
0.03
0.001
1
NIL
HORIZONTAL

SLIDER
3
216
175
249
nbmarches
nbmarches
1
3
3
1
1
NIL
HORIZONTAL

SLIDER
3
257
175
290
nb-taxis
nb-taxis
1
10
6
1
1
NIL
HORIZONTAL

SLIDER
2
297
174
330
nb-villageois
nb-villageois
5
500
190
5
1
NIL
HORIZONTAL

SLIDER
1
341
173
374
contrainte-distance
contrainte-distance
1
50
10
1
1
NIL
HORIZONTAL

SLIDER
2
425
174
458
facteur-vitesse
facteur-vitesse
5
20
20
1
1
NIL
HORIZONTAL

SLIDER
3
468
174
501
capacite-max-taxis
capacite-max-taxis
5
20
10
1
1
NIL
HORIZONTAL

PLOT
746
10
1119
296
Nb villageois arrives
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"marche1" 1.0 0 -2674135 true
"marche3" 1.0 0 -13345367 true
"marche2" 1.0 0 -10899396 true
"marche4" 1.0 0 -2064490 false
"marche5" 1.0 0 -13345367 false

PLOT
933
299
1116
444
efficacite
NIL
NIL
0.0
1.0
0.0
10.0
true
false
PENS
"default" 1.0 1 -16777216 true

MONITOR
992
549
1056
594
traffic max
max [traffic-brut] of links
17
1
11

BUTTON
66
47
121
80
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
896
549
988
594
taux de desserte
(nb-villageois-au-marche-total / nb-villageois-total-jours) * 100
1
1
11

MONITOR
1058
549
1115
594
jours
jours
17
1
11

SLIDER
3
507
175
540
nb-ticks-jours
nb-ticks-jours
500
2000
1000
10
1
NIL
HORIZONTAL

MONITOR
1057
502
1114
547
NIL
ticks
17
1
11

@#$#@#$#@
LE MODELE TAXI BROUSSE
-----------

Le mod�le concerne la production de services de transports de voyageurs non r�gul� en milieu rural africain, services consistant � acheminemer des villadeois vers un ou des march�s.
Le mod�le doit permettre d'�tudier les ph�nom�nes de convergence sur un ou des points centraux (les march�s) � partir de plusieurs points secondaires (les stations) situ�s sur un r�seau de transport et vers lesquels convergent une population dispers�e dans l�espace. Cette double convergence alimente un processus d�auto-renforcement des centres, lui-m�me produisant une diff�renciation de l�espace.
Il s'agit d'observer plusieurs processus : l�auto renforcement (polarisation sur quelques stations et diff�renciation des march�s); l��mergence de bassins d�attraction; la diff�renciation croissante des axes de circulation; une efficacit� diff�renci�e des comportements des taxis influenc�s par les ph�nom�nes de polarisation.


PROCESSUS DU MODELE
-----------

- Les villageois, au d�but dispers�s dans l�espace, convergent vers les villages-stations selon un mod�le gravitaire. Chaque villageois souhaite prendre un taxi pour se rendre � un march� vers lequel il est attir� selon un m�me mod�le gravitaire.
- Les taxis parcourent le r�seau � la recherche de clients de mani�re al�atoire. 
Arriv�s � une station, ils prennent des passagers allant dans une m�me direction (tirage au sort a priori favorable � la destination pour laquelle les passagers sont les plus nombreux). 
- Une fois les passagers embarqu�s, les taxis se dirigent vers le march� en suivant le plus court chemin. En route, ils peuvent embarquer d�autres passagers pour la m�me destination, dans la limite de leur capacit� de charge
- Arriv�s au march�, les passagers sont d�barqu�s, ils ��sortent�� du jeu, et les taxis repartent � la recherche de clients.
- L�attractivit� des villages-stations est fonction du nombre de voyageurs qui y ont �t� embarqu�s. Plus le nombre de villageois ayant pris un taxis en un point est �lev�, plus ce point est attractif pour les villageois.
- L�attractivit� des march�s est fonction du nombre de voyageurs qui y sont d�barqu�s. Plus le nombre de villageois arriv�s � un  march� est �lev�, plus il est attractif pour les villageois.
- De nouveaux villageois arrivent par ��vagues�� successives d�s que le nombre de villageois encore ��en jeu�� diminue fortement, ce qui contribue � faire vivre le mod�le en permanence.


UTILISATION
-----------

- Configurer un r�seau de mani�re al�atoire en d�finissant le nombre de n�uds et de march�s, nombre de liens cr��s (les n�uds sont li�s les uns aux autres selon une fonction de distance).

- Une fois le r�seau configur�, faire varier les param�tres : nombre de villageois, nombre de taxis, leur capacit� de chargement, diff�rentiel de vitesse entre taxis et villageois (pi�tons), nombre de ticks par jour.

Les indicateurs observ�s sont :
- La polarisation des march�s qui est fonction du nombre de villageois arriv�s.
- L�efficacit� des taxis qui est le rapport entre le nombre de n�uds emprunt�s et le nombre de n�uds sur lesquels le taxi a embarqu� des passagers. Quand ce rapport tend vers la valeur 1, l�efficacit� est maximale (le taxi embarque des passagers dans tous - les n�uds parcourus), quand il tend vers 0, elle est minimale.
- Le nombre maximum de passages sur un lien (les liens deviennent de plus en plus gros en fonction du nombre de passages)
- Le taux de desserte qui est un indicateur d�efficacit� globale : il s�agit du rapport entre le nombre de villageois arriv�s � destination et le nombre total de villageois pour un ��jour�� (soit � chaque fois qu�une nouvelle population de villageois est ��lanc�e�� dans le jeu)


OBSERVATIONS
---------

- Sur le processus d�auto-renforcement : apr�s quelques it�rations, apparition d'une structure centrale dans le r�seaux repr�sent�s par les axes et quelques n�uds qui permettent d�acc�der aux march�s. Selon la configuration initiale, on voit �merger soit une sorte de colonne vert�brale, soit deux ou plusieurs bassins (en fonction du nombre de march�s choisi au d�part) assez peu reli�s entre eux. Les figures qui se dessinent se rapprochent plus de celle de l�arbre (un tronc et des branches) que de celle de l��toile. 

- Apparition de zones enclav�es o� les villageois n�ont que peu ou pas de chance d�acc�der � un taxi. Progressivement, les villageois se tournent vers d�autres villages stations, plus �loign�s mais plus attractifs car la probabilit� d�y avoir un taxi y est plus grande. L�indice d�efficacit� globale, le taux de desserte, �volue par phases. Dans un premier temps il reste bas, puis atteint progressivement des valeurs assez �lev�es au fur et � mesure que le nombre de villageois encore en jeu se r�duit, for�ant les taxis � parcourir les branches les plus �loign�es et isol�es du graphes. L�arriv�e de nouveaux villageois fait chuter la valeur de l�indice qui finit par se stabiliser autour de valeurs qui montrent globalement une efficacit� assez faible. La r�orientation progressive des villageois (pi�tons) vers les villages les plus attractifs a-t-elle un impact sur cet indicateur ? � voir en laissant le jeu tourner assez longtemps.


DYSFONCTIONNEMENT A RESOUDRE
-----------

- A l'initialisation, les villageois qui vont directement au march� � pieds ne meurent pas, du coup les taxis les chargent lorsqu'ils sont au march� et ils les d�chargent quand ils y reviennent.

- Certains taxis ne prennent aucun villageois � des stations alors qu'ils sont vides.

- Certains taxis peuvent rester sur un m�me lien pendant un certain temps.


PERSPECTIVES
---------

- Les transporteurs adaptent-ils leurs strat�gies entre logique de concurrence et logique de compl�mentarit� ?
- Quels sont les impacts de ces strat�gies sur l��mergence de formes spatiales (bassins / r�seaux) ? 
- Quel est le r�le des configurations initiales dans l��mergence de ph�nom�nes de polarisation ?
- Comment pourraient �voluer les demandes et les comportements des villageois pour s�adapter � l�offre ?
- Quels pourraient �tre les leviers de r�gulation ? : nbre de taxis et lignes de transport fixes...





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
NetLogo 4.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
