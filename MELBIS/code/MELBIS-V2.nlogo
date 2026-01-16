;; Comments initialed with -AL or -JLK indicate comments from the researchers
;; Commments without initials are used to comment out certain procedure steps

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; MELBIS-V2
;;;;; To cite:
;;;;; Anderson, T., Leung, A., Perez, L. et al.
;;;;; Investigating the Effects of Panethnicity in Geospatial Models of Segregation.
;;;;; Appl. Spatial Analysis 14, 273–295 (2021). https://doi.org/10.1007/s12061-020-09355-2
;;;;;    and
;;;;; Anderson, T, Leung, A, Dragicevic, S, Perez, L.
;;;;; Modeling the geospatial dynamics of residential segregation in three Canadian cities: An agent‐based approach.
;;;;; Transactions in GIS. 2021; 25(2): 948 – 967. https://doi.org/10.1111/tgis.12712


extensions [gis]

globals ; variables that hold the raster datasets- AL
[
  africansDs
  asiansDs
  asiansubsetDs
  americansDs
  europeansDs
  chineseDs ;;- added by ACL
  southasianDs
  childrenDs
  enFrDs
  englishDs
  frenchDs
  medAgeDs
  medIncomeDs
  populationDs
  resDS
  busDs
  schoolsDs
  metroDs
  parksDs
  commerceDs
]

patches-own ; variables that describe the individual patch- AL
[
  africans
  asians
  asiansubsets
  americans
  europeans
  chinese
  southasians
  children
  enFr
  english
  french
  medAge
  medIncome
  population
  is_res
  bus
  school
  metro
  park
  commerce
  africanMean
  americanMean
  asianMean
  asiansubsetMean
  chineseMean
  europeanMean
  southasianMean
  frenchMean
  englishMean
  enFrMean
  schoolsMean
  metros
  buses
  parks
  commerces
  schools
]
breed[Immigrants Immigrant]

Immigrants-own ; variables assigned to immigrants- AL
[
  hasSpouseDependant
  ; Do they have a spouse or a dependant?

  nbChildren
  ;How many children?

  ethnicity
  ;What is the ethnicity?

  age
  ;What is the age of the immigrant?

  married?
  ;Is the immigrant a married couple?

  income
  ;Annual Income

  typeImmigrant
  ;Type of immigant: 1. Student 2. Skilled Worker 3. Refugee 4. ???

  language
  ;Spoken language: French, English or Both

  defined?
  ;Are the agents sorted in groups?

  education
  ;What is the level of education. Superior or None

  satisfied
  ;Are the agents satisfied by their location?

  settled
  ;Agents who are satisfied are settled

  step
  ;Where are the agents in their decision process. Starts with Step1.

;  Choice0
  Choice1
  Choice2
  Choice3
  Choice4
  Choice5

]

breed[Residents Resident]



to setup ; runs setup procedures for importing raster datasets, creates individual agents, assigns values to those agents and calculates the averages for each neighbourhood- AL
  ca
  reset-ticks
  ;set-default-shape Residents "house"
  ;set-default-shape Immigrants "house"
  importGis
  createPeople
  giveValueToImmigrants
  compute_neighborhoods
end

to go ; go procedures that runs each decision-making step and assigns agents to their final location. Decision-making steps can be re-ordered by changing the order of the select-choice function AL
  if ticks < 5
  [
   select_choice1
   select_choice2
   select_choice3
   select_choice4
   select_choice5
   segregate
   satisfaction
  ; ask Immigrants [move-to one-of Choice5]
   tick
   go
  ]
end


to importGis ;; Imports raster layers in .asc format
  print "Importing GIS Layers..."
  ask patches [set pcolor white]
  set resDS gis:load-dataset "2011_res.asc"
  gis:set-world-envelope-ds gis:envelope-of resDS
  gis:apply-raster resDS is_res
  ask patches with [is_res = 1] [set pcolor gray + 1]

;;;;;;;;;;;;;;;;;;;;;;;; Population datasets represent the percentage of population with the given variable present in a cell. Percentages are calculated using Statistic Canada Data. -JLK/AL

  set africansDs gis:load-dataset "2011_africans.asc"
  gis:apply-raster africansDs africans
  ask patches with [africans > 20] [set pcolor black]

  set asiansDs gis:load-dataset "2011_asians.asc"
  gis:apply-raster asiansDs asians
  ;ask patches with [asians > 20] [set pcolor orange]

  set chineseDs gis:load-dataset "2011_chinese.asc"
  gis:apply-raster chineseDs chinese
  ;ask patches with [asians > 20] [set pcolor orange]

  set southasianDs gis:load-dataset "2011_southasians.asc"
  gis:apply-raster southasianDs southasians

  set asiansubsetDs gis:load-dataset "2011_asianssubset.asc"
  gis:apply-raster asiansubsetDs asiansubsets

  set americansDs gis:load-dataset "2011_americans.asc"
  gis:apply-raster americansDs americans
  ;ask patches with [americans > 20] [set pcolor green]

  set europeansDs gis:load-dataset "2011_europeans.asc"
  gis:apply-raster europeansDs europeans
  ;ask patches with [europeans > 20] [set pcolor red]

  ;set childrenDs gis:load-dataset "2011_children.asc"
  ;gis:apply-raster childrenDs children
  ;ask patches with [children > 1] [set pcolor blue]

  ;set enFrDs gis:load-dataset "2011_En_Fr.asc"
  ;gis:apply-raster enFrDs enFr
  ;ask patches with [enFr > 20] [set pcolor brown]

  set englishDs gis:load-dataset "2011_english.asc"
  gis:apply-raster englishDs english
  ;ask patches with [english > 30] [set pcolor blue]

  ;set frenchDs gis:load-dataset "2011_french.asc"
  ;gis:apply-raster frenchDs french
  ;ask patches with [french > 30] [set pcolor pink]

  set medAgeDs gis:load-dataset "2011_medage.asc"
  gis:apply-raster medAgeDs medAge
  ;ask patches with [medAge > 50] [set pcolor green]

  set medIncomeDs gis:load-dataset "2011_medincome.asc"
  gis:apply-raster medIncomeDs medIncome
  ;ask patches with [medIncome > 50000] [set pcolor red]

  set populationDs gis:load-dataset "2011_pop.asc"
  gis:apply-raster populationDs population
  ;ask patches with [population > 3000] [set pcolor white]

;;;;;;;;;;;;;;;;;;;;;;;; The following variables are represented as binary rasters -JLK

  set busDs gis:load-dataset "2011_transit.asc" ;; transit for Vancouver is both SkyTrain and bus- ACL
  gis:apply-raster busDs bus
  ask patches with [bus = -3.4] [set bus 0]

  set schoolsDs gis:load-dataset "2011_schools.asc"
  gis:apply-raster schoolsDs school
  ask patches with [school = -3.4] [set school 0]

  ;set metroDs gis:load-dataset "2011_metro.asc" commented out because 2011_transit.asc covers both SkyTrain and buses for Vancouver- ACL
  ;gis:apply-raster metroDs metro
  ;ask patches with [metro = -3.4] [set metro 0]

  set parksDs gis:load-dataset "2011_parks.asc"
  gis:apply-raster parksDs park
  ask patches with [park = -3.4] [set park 0]

  set commerceDs gis:load-dataset "2011_commerce.asc"
  gis:apply-raster commerceDs commerce
  ask patches with [commerce = -3.4] [set commerce 0]

  print "layer importation successful"

end


to compute_neighborhoods ; each ask statement calculates the mean number of individuals, assets or landuse types within a certain number of patches-AL
  print "Computing mean values of neighborhoods"
  print "Computing african mean"
  ask patches with [africans > 0] [set africanMean mean [africans] of patches in-radius 4 with [africans > 0]]
  print "Computing american mean"
  ask patches with [americans > 0] [set americanMean mean [americans] of patches in-radius 4 with [americans > 0]]
  print "Computing asian mean"
  ask patches with [asians > 0] [set asianMean mean [asians] of patches in-radius 4 with [asians > 0]]
  print "Computing asian subset mean"
  ask patches with [asiansubsets > 0] [set asiansubsetMean mean [asiansubsets] of patches in-radius 4 with [asiansubsets > 0]]
  print "Computing chinese mean"
  ask patches with [chinese > 0] [set chineseMean mean [chinese] of patches in-radius 4 with [chinese > 0]]
  print "Computing european mean"
  ask patches with [europeans > 0] [set europeanMean mean [europeans] of patches in-radius 4 with [europeans > 0]]
  ;; print "Computing french language mean"
  ;; ask patches with [french > 0] [set frenchMean mean [french] of patches in-radius 12 with [french > 0]]
  print "Computing south asian mean"
  ask patches with [southasians > 0] [set southasianMean mean [southasians] of patches in-radius 4 with [southasians > 0]]
  print "Computing english language mean"
  ask patches with [english > 0] [set englishMean mean [english] of patches in-radius 12 with [english > 0]]
 ;; print "Computing english/french mean"
 ;; ask patches with [enFr > 0] [set enFrMean mean [enFr] of patches in-radius 12 with [enFr > 0]]
  print "Computing transit count"
  ask patches with [is_res = 1] [set buses count patches in-radius 8 with [bus = 1]]
  ;; print "Computing metro count"
  ;; ask patches with [is_res = 1] [ set metros count patches in-radius 8 with [metro = 1]]
  print "computing school count"
  ask patches with [is_res = 1] [ set schools count patches in-radius 16 with [school = 1]]
  print "computing park count"
  ask patches with [is_res = 1] [ set parks count patches in-radius 16 with [park = 1]]
  print "computing commerce count"
  ask patches with [is_res = 1] [ set commerces count patches in-radius 32 with [commerce = 1]]

  print "finished mean values computation"
end


to createPeople; generates 13,334 residents and 6666 immigrants
;;;;;;;;;;;;;;;;;;;;;;;; Residents do not move, Immigrants will move -JLK
  print "Creating residents and immigrants"
  ask n-of 13334 patches with [is_res = 1] [sprout-Residents 1 [set color blue set size 1 ]]
  ask n-of 6666 patches with [is_res = 1 and not any? turtles-here] [sprout-Immigrants 1 [set size 1 set satisfied "False" set step 1]]
end

to giveValueToImmigrants
;;;;;;;;;;;;;;;;;;;;;;;; This procedure gives a demographic profile to each immigrant based on statistics of immigration in the longitudinal immigration database and average incomes for individuals with a certain type of degree
;;; gives a subset of the immigrant agents an ethnicity based on the breakdown of immigrants in a given city
  ask n-of (0.033 * 6666) Immigrants [set color black set nbChildren random 4 set ethnicity "african" set defined? true];; Changed to BC Values- ACL
  ask n-of (0.093 * 6666) Immigrants with [defined? != true] [set color pink set nbChildren random 4 set ethnicity "american" set defined? true] ;; Changed to BC Values- ACL
  ;ask n-of (0.585 * 6666) Immigrants with [defined? != true] [set color yellow set nbChildren random 4 set ethnicity "asian" set defined? true] ;; Changed to BC Values (aaron took off 12%)
  ask n-of (0.298 * 6666) Immigrants with [defined? != true] [set color red set nbChildren random 4 set ethnicity "chinese" set defined? true] ;; Test value
  ask n-of (0.136 * 6666) Immigrants with [defined? != true] [set color brown set nbChildren random 4 set ethnicity "south asian" set defined? true] ;; Test value
  ask n-of (0.151 * 6666) Immigrants with [defined? != true] [set color green set nbChildren random 4 set ethnicity "asian subset" set defined? true] ;; Test value
  ask Immigrants with [defined? != true] [set color yellow set nbChildren random 4 set ethnicity "european"]

  ;; Gives Agents a Settled/Unsetteled Status

  ask n-of (1 * 6666) Immigrants [set settled 0]

  ;; Gives Agent an Immigrant Type (Skilled Worker, Business, Refugee) (Need to Change to Experience Class, Caregiver)- Changed to IMDB values for British Columbia
  ask Immigrants [set defined? false]
  ask n-of (0.31 * 6666) Immigrants [set typeImmigrant "Skilled Worker" set defined? true] ;; amended using the IMDB categories (2011)- ACL
  ask n-of (0.08 * 6666) Immigrants with [defined? != true] [set typeImmigrant "Business" set defined? true] ;; amended using the IMDB categories (2011)- ACL
  ask n-of (0.25 * 6666) Immigrants with [defined? != true] [set typeImmigrant "Prov Sponsor" set defined? true] ;; added using the IMDB categories (2011)- ACL
  ask n-of (0.11 * 6666) Immigrants with [defined? != true] [set typeImmigrant "Caregiver" set defined? true] ;; addfed using the IMDB categories (2011)- ACL
  ask n-of (0.13 * 6666) Immigrants with [defined? != true] [set typeImmigrant "CEC" set defined? true] ;; added using the IMDB categories (2011)- ACL
  ask Immigrants with [defined? != true] [set typeImmigrant "Refugee"]


  ;; Gives agent an education level (Basic, Advanced or None) (Arbitrary, but made inclusive of both language and formal education skills)
  ask Immigrants[
    ifelse (random-float 1 < 0.33 AND (typeImmigrant = "Refugee")) [set education "None"]
    [ifelse (random-float 1 > 0.66 AND (typeImmigrant = "Refugee" OR typeImmigrant = "Skilled Worker" OR typeImmigrant = "Prov Sponsor" OR typeImmigrant = "Business" OR typeImmigrant = "CEC" or typeImmigrant = "Caregiver")) [set education "Advanced"]
      [set education "Basic"]]]

  ;ask n-of (0.651 * 3333) Immigrants [set language "French" set defined? true] - French removed for Vancouver model- ACL

  ask n-of (1 * 6666) Immigrants [set language "English" set defined? true]
  ;ask Immigrants with [defined? != true] [set language "Both" set defined? true] - English and french removed for Vancouver model- ACL
  ask Immigrants [set defined? false]

  ;; Gives Agent an Income based on the the mean income of a given immigrant in a given IMDB classification with an income bonus for individuals with an advanced education- AL
  ask Immigrants [set defined? false]
  ask Immigrants[
    ifelse (typeImmigrant = "Skilled Worker" AND education = "Basic") [set income (9900 + (random 10001) - (random 5001))]
    [ifelse (typeImmigrant = "CEC" AND education = "Basic") [set income (39100 + (random 10001) - (random 5001))]
      [ifelse (typeImmigrant = "Prov Sponsor" AND education = "Basic") [set income (34600 + (random 10001) - (random 5001))]
        [ifelse (typeImmigrant = "Business" AND education = "Basic") [set income (7700 + (random 10001) - (random 5001))]
          [ifelse (typeImmigrant = "Caregiver" AND education = "Basic") [set income (19200 + (random 10001) - (random 5001))]
            [ifelse (typeImmigrant = "Refugee" AND education = "Basic" OR education = "None") [set income (10900 + (random 10001) - (random 5001))]
;; Add income bonus for immigrants with "advanced" education. Multiply the median income by 0.525 (average difference between high school and bachlelor degree income is 52.5%, add as bonus- AL
              [ifelse (typeImmigrant = "Skilled Worker" AND education = "Advanced") [set income (9900 + (random 10001) - (random 5001) + 5198)]
                [ifelse (typeImmigrant = "CEC" AND education = "Advanced") [set income (39100 + (random 10001) - (random 5001) + 20528)]
                  [ifelse (typeImmigrant = "Prov Sponsor" AND education = "Advanced") [set income (34600 + (random 10001) - (random 5001) + 18165)]
                    [ifelse (typeImmigrant = "Business" AND education = "Advanced") [set income (7700 + (random 10001) - (random 5001) + 4043)]
                      [ifelse (typeImmigrant = "Caregiver" AND education = "Advanced") [set income (19200 + (random 10001) - (random 5001) + 10080)]
                        [ifelse (typeImmigrant = "Refugee" AND education = "Advanced") [set income (10900 + (random 10001) - (random 5001) + 5723 )]
                          [set income 0]]]]]]]]]]]]]



end

;;;;;;;;;;;;;;;;;;; The following "choices" are the five rules used to determine where the immigrants go. These choice procedures repeatedly subset a set of suitable patches. -JLK

;;;;;;; choice 1 selects suitable patches based on the ethnolingustic requirement of each agent. It looks for patches with a certain percentage of similar neighbours (based on the variable slider) and enough similar language speakeres- AL

to select_choice1
  ;;;;;;;;;;;;;;;;;;; Choice 1 is based on ethnicity and language -JLK
  ;; print "selection of best areas for african speaking french"
  ;; ifelse count patches with [not any? Residents-here and africanMean > desired_neighbors and frenchMean > 50] > 0
  ;; [ask immigrants with [ethnicity = "african" and language = "French"]
  ;; [set choice1 patches with [not any? Residents-here and africanMean > desired_neighbors and frenchMean > 50]]][ask immigrants with [ethnicity = "african" and language = "French"] [set Choice1  patches with [not any? Residents-here and africanMean > 10 and frenchMean > 50]]]

  print "selection of best areas for african speaking english"
  ifelse count patches with [not any? Residents-here and africanMean > desired_neighbors and englishMean > 50 and is_res = 1] > 0
  [ask immigrants with [ethnicity = "african" and language = "English" and settled = 0][set choice1 patches with  [not any? Residents-here and africanMean > desired_neighbors and englishMean > 50 and is_Res = 1]]]
  [ask immigrants with [ethnicity = "african" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and africanMean > 10 and englishMean > 50 and is_Res = 1]]]
 ; show [choice1] of immigrants

  ;; print "selection of best areas for african speaking engligh and french"
  ;; ifelse count patches with [not any? Residents-here and africanMean > desired_neighbors and (english > 50 or french > 50)] > 0
  ;; [ask immigrants with [ethnicity = "african" and language = "Both"]
  ;; [set choice1 patches with [not any? Residents-here and africanMean > desired_neighbors and (english > 50 or french > 50)]]][ask immigrants with [ethnicity = "african" and language = "Both"] [set Choice1  patches with [not any? Residents-here and africanMean > 10 and (french > 50 or english > 50)]]]

  ;; print "selection of best areas for americans speaking french"
  ;; ifelse count patches with [not any? Residents-here and americanMean > desired_neighbors and frenchMean > 50] > 0
  ;; [ask immigrants with [ethnicity = "american" and language = "French"]
  ;; [set choice1 patches with [not any? Residents-here and americanMean > desired_neighbors and frenchMean > 50]]][ask immigrants with [ethnicity = "american" and language = "French"] [set Choice1  patches with [not any? Residents-here and africanMean > 10 and frenchMean > 50]]]

  print "selection of best areas for american speaking english"
  ifelse count patches with [not any? Residents-here and americanMean > desired_neighbors and englishMean > 50 and is_res = 1] > 0
  [ask immigrants with [ethnicity = "american" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and americanMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  [ask immigrants with [ethnicity = "american" and language = "English" and settled = 0] [set choice1  patches with [not any? Residents-here and americanMean > 10 and englishMean > 50 and is_res = 1]]]

  ;; print "selection of best areas for american speaking engligh and french"
  ;; ifelse count patches with [not any? Residents-here and americanMean > desired_neighbors and (english > 50 or french > 50)] > 0
  ;; [ask immigrants with [ethnicity = "american" and language = "Both"]
  ;; [set choice1 patches with [not any? Residents-here and americanMean > desired_neighbors and (english > 50 or french > 50)]]] [ask immigrants with [ethnicity = "american" and language = "Both"][set Choice1  patches with [not any? Residents-here and africanMean > 10 and (french > 50 or english > 50)]]]

  ;; print "selection of best areas for asians speaking french"
  ;; ifelse count patches with [not any? Residents-here and asianMean > desired_neighbors and frenchMean > 50] > 0
  ;; [ask immigrants with [ethnicity = "asian" and language = "French"]
  ;; [set choice1 patches with [not any? Residents-here and asianMean > desired_neighbors and frenchMean > 50]]][ask immigrants with [ethnicity = "asian" and language = "French"] [set Choice1  patches with [not any? Residents-here and africanMean > 10 and frenchMean > 50]]]

  ;;print "selection of best areas for asian speaking english"
  ;;ifelse count patches with [not any? Residents-here and asianMean > desired_neighbors and englishMean > 50] > 0
  ;;[ask immigrants with [ethnicity = "asian" and language = "English"][set choice1 patches with [not any? Residents-here and asianMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  ;;[ask immigrants with [ethnicity = "asian" and language = "English"][set Choice1 patches with [not any? Residents-here and asianMean > 10 and englishMean > 50 and is_res = 1]]]
  ;; show [choice1] of immigrants

  print "selection of best areas for chinese speaking english"
  ifelse count patches with [not any? Residents-here and chineseMean > desired_neighbors and englishMean > 50] > 0
  [ask immigrants with [ethnicity = "chinese" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and chineseMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  [ask immigrants with [ethnicity = "chinese" and language = "English" and settled = 0][set Choice1 patches with [not any? Residents-here and chineseMean > 10 and englishMean > 50 and is_res = 1]]]
  ;; show [choice1] of immigrants

  print "selection of best areas for south asians speaking english"
  ifelse count patches with [not any? Residents-here and southasianMean > desired_neighbors and englishMean > 50] > 0
  [ask immigrants with [ethnicity = "south asian" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and southasianMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  [ask immigrants with [ethnicity = "south asian" and language = "English" and settled = 0][set Choice1 patches with [not any? Residents-here and southasianMean > 10 and englishMean > 50 and is_res = 1]]]
  ;; show [choice1] of immigrants

  print "selection of best areas for asian subsets speaking english"
  ifelse count patches with [not any? Residents-here and asiansubsetMean > desired_neighbors and englishMean > 50] > 0
  [ask immigrants with [ethnicity = "asian subset" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and asiansubsetMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  [ask immigrants with [ethnicity = "asian subset" and language = "English" and settled = 0][set Choice1 patches with [not any? Residents-here and asiansubsetMean > 10 and englishMean > 50 and is_res = 1]]]
  ;; show [choice1] of immigrants

  ;; print "selection of best areas for asian speaking engligh and french"
  ;; ifelse count patches with [not any? Residents-here and asianMean > desired_neighbors and (english > 50 or french > 50)] > 0
  ;; [ask immigrants with [ethnicity = "asian" and language = "Both"]
  ;; [set choice1 patches with [not any? Residents-here and asianMean > desired_neighbors and (english > 50 or french > 50)]]] [ask immigrants with [ethnicity = "asian" and language = "Both"][set Choice1  patches with [not any? Residents-here and africanMean > 10 and (french > 50 or english > 50)]]]

  ;; print "selection of best areas for europeans speaking french"
  ;; ifelse count patches with [not any? Residents-here and europeanMean > desired_neighbors and frenchMean > 50] > 0
  ;; [ask immigrants with [ethnicity = "european" and language = "French"]
  ;; [set choice1 patches with [not any? Residents-here and europeanMean > desired_neighbors and frenchMean > 50]]][ask immigrants with [ethnicity = "european" and language = "French"] [set Choice1  patches with [not any? Residents-here and africanMean > 10 and frenchMean > 50]]]

  print "selection of best areas for european speaking english"
  ifelse count patches with [not any? Residents-here and europeanMean > desired_neighbors and englishMean > 50 and is_res = 1] > 0
  [ask immigrants with [ethnicity = "european" and language = "English" and settled = 0][set choice1 patches with [not any? Residents-here and europeanMean > desired_neighbors and englishMean > 50 and is_res = 1]]]
  [ask immigrants with [ethnicity = "european" and language = "English" and settled = 0] [set Choice1  patches with [not any? Residents-here and europeanMean > 10 and englishMean > 50 and is_res = 1]]]

  ;; print "selection of best areas for european speaking engligh and french"
  ;; ifelse count patches with [not any? Residents-here and europeanMean > desired_neighbors and (english > 50 or french > 50)] > 0
  ;; [ask immigrants with [ethnicity = "european" and language = "Both"]
  ;; [set choice1 patches with [not any? Residents-here and europeanMean > desired_neighbors and (english > 50 or french > 50)]]] [ask immigrants with [ethnicity = "european" and language = "Both"][set Choice1  patches with [not any? Residents-here and africanMean > 10 and (french > 50 or english > 50)]]]
end

to select_choice2
;;;;;;;;;;;;;;;; Choice 2 is based on the median income of a given patch. Immigrants approve of a patch if it is within a specific range relative to the agent's income
  print "Subsetting patches from choice1 in regards to the income"
  ask immigrants with [count Choice1 > 1] [
    ifelse (count Choice1 with [medincome > [income] of myself - 10000 and medincome < [income] of myself + 5000 and is_res = 1] > 0) [set Choice2 Choice1 with [medincome > [income] of myself - 10000 and medincome < [income] of myself + 5000 and is_res = 1]][set Choice2 Choice1]]
  print "Finished"
end

to select_choice3
;;;;;;;;;;;;;;;; Choice 3 is based on access to schools -JLK
  print "Subsetting patches from Choice2 in regards to the schools for people with children"
  ask Immigrants with [nbChildren > 0] [ifelse count Choice2 with [schools > 0 and is_res = 1] > 0 [set Choice3 Choice2 with [schools > 0 and is_res = 1]][set Choice3 Choice2]]
  ask Immigrants with [nbChildren = 0] [set Choice3 Choice2]
  print "Finished"
end

to select_choice4
;;;;;;;;;;;;;;;; Choice 4 is based on neighborhood quality (parks and commerce) -JLK
  print "Subsetting patches from Choice 3 in regards to the neighbourhood quality (parks and commerce)"
  ask Immigrants [set defined? false]
  ask Immigrants with [typeImmigrant = "Business"] [if count Choice3 with [parks > 0 and commerces > 0 and is_res = 1] > 0 [set Choice4 Choice3 with [parks > 0 and commerces > 0 and is_res = 1] set defined? true]]
  ask n-of (1 * count Immigrants with [typeImmigrant = "Skilled Worker"]) Immigrants with [typeImmigrant = "Skilled Worker"] [if count Choice3 with [parks > 0 and commerces > 0 and is_res = 1] > 0 [set Choice4 Choice3 with [parks > 0 and commerces > 0 and is_res = 1] set defined? true]]
  ask Immigrants with [defined? != true] [set Choice4 Choice3]
  print "Finished"
end

to select_choice5
;;;;;;;;;;;;;;;; Choice 5 is based on access to public transit -JLK
  print "Subsetting patches from choice 4 based on access to public transit"
  ask Immigrants [ifelse count Choice4 with [(buses > nbBus) or (metros > 0) and is_res = 1] > 0 [set Choice5 Choice4 with [buses > nbBus or metros > 0 and is_res = 1]] [set Choice5 Choice4]]
  print "Finished"
end

to segregate ;; asks immigrants to move to one of their suitable patches
  print "Immigrants Moving to Their Choice Location"
ask Immigrants [ifelse count Choice5 with [not any? turtles-here] > 0 [move-to one-of Choice5 with[not any? turtles-here]]
[ifelse count Choice5 with [count turtles-here <= 15] > 0 [move-to one-of Choice5 with [count turtles-here <= 15]]
[move-to one-of Choice5]]]
end

to satisfaction ; asks immigrants to check if there are 15 or fewer agents in their patch. If there are 15 or fewer, they are satisfied and therefore settled. If there are 15 or more, they are unsatisfied and will move on the next tick.
  print "Checking Immigrant Satisfaction"
  ask Immigrants
  [
    ifelse count Choice5 with [count turtles-here <= 15] > 0 [set satisfied "True"]
    [set satisfied "False"]
  ]
  print "Complete. Creating agentset for Immigrants who are unsatisfied"

  ask Immigrants
  [
    ifelse satisfied = "True" [set settled 1]
    [set settled 0]
  ]
end

to Export_To_Shapefile ;; packages agents into a .shp file for import into ArcGIS- AL
  gis:set-world-envelope-ds gis:envelope-of resDS
   ask Immigrants [set Choice1 count Choice1 set Choice2 count Choice2 set Choice3 count Choice3 set Choice4 count Choice4 set Choice5 count Choice5]
     let carte gis:turtle-dataset Immigrants
  gis:store-dataset carte user-new-file
end

to Export_BehaviorSpace ;; packages agents from each behaviourspace experiment into a .shp file for import into ArcGIS using a standardized file name- AL
  gis:set-world-envelope-ds gis:envelope-of resDS
  ask Immigrants [set Choice1 count Choice1 set Choice2 count Choice2 set Choice3 count Choice3 set Choice4 count Choice4 set Choice5 count Choice5]
     let carte gis:turtle-dataset Immigrants
  let experimentName behaviorspace-experiment-name
  let experimentNumber behaviorspace-run-number
  let fileName word experimentName experimentNumber
  gis:store-dataset carte fileName
end

; I, JLK, am not the original author of the code, I've just helped comment it.
@#$#@#$#@
GRAPHICS-WINDOW
401
52
1320
833
-1
-1
1.468
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
620
0
525
1
1
1
ticks
30.0

BUTTON
187
52
289
140
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
1

BUTTON
289
52
391
140
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
1

PLOT
187
216
391
410
Pct Satisfaction
Ticks
Pct
0.0
4.0
0.0
100.0
false
false
"" ""
PENS
"Immigrants" 1.0 0 -7500403 true "" "plot count Immigrants with [satisfied = \"True\"] / count Immigrants * 100"
"European" 1.0 0 -13840069 true "" ""
"American" 1.0 0 -5298144 true "" ""
"pen-3" 1.0 0 -8431303 true "" ""

MONITOR
8
554
172
599
Percent Satistified with Choice1
count Immigrants with [count Choice1 > 0] / count Immigrants * 100
3
1
11

MONITOR
8
599
172
644
Percent Satisfied with Choice2
count Immigrants with [count Choice2 > 0] / count Immigrants * 100
2
1
11

MONITOR
8
644
172
689
Percent Satisfied with Choice3
count Immigrants with [count Choice3 > 0] / count Immigrants * 100
2
1
11

MONITOR
8
689
172
734
Percent Satisfied with Choice4
count Immigrants with [count Choice4 > 0] / count Immigrants * 100
2
1
11

MONITOR
8
734
172
779
Percent Satisfied with Choice5
count Immigrants with [count Choice5 > 0] / count Immigrants * 100
2
1
11

BUTTON
187
140
391
173
NIL
Export_To_Shapefile
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
8
52
180
85
desired_neighbors
desired_neighbors
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
135
180
168
nbBus
nbBus
0
100
5.0
1
1
Buses
HORIZONTAL

TEXTBOX
8
175
158
203
This is for choosing the number of buses desired
11
0.0
1

TEXTBOX
8
93
158
135
This is for choosing the number of same ethnicity (percentage) neighborhood
11
0.0
1

MONITOR
8
216
163
261
Overall Immigrant Satisfaction
count Immigrants with [satisfied = \"True\"] / count Immigrants * 100
2
1
11

MONITOR
8
261
163
306
European Satisfaction
count Immigrants with [ethnicity = \"european\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"european\"]* 100
2
1
11

MONITOR
8
306
163
351
American Satisfaction
count Immigrants with [ethnicity = \"american\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"american\"] * 100
2
1
11

MONITOR
8
351
163
396
African Satisfaction
count Immigrants with [ethnicity = \"african\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"african\"] * 100
2
1
11

MONITOR
8
396
163
441
Chinese Satisfaction
count Immigrants with [ethnicity = \"chinese\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"chinese\"] * 100
2
1
11

MONITOR
8
441
163
486
South Asian Satisfaction
count Immigrants with [ethnicity = \"south asian\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"south asian\"] * 100
2
1
11

MONITOR
8
486
163
531
Asian Subset Satisfaction
count Immigrants with [ethnicity = \"asian subset\" and satisfied = \"True\"] / count Immigrants with [ethnicity = \"asian subset\"] * 100
2
1
11

BUTTON
187
173
391
206
NIL
Export_BehaviorSpace
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
187
421
383
706
INSTRUCTIONS\n\n1) Adjust experiment parameters \"desired_neighbors\" and \"nbBus\" sliders in the top left.\n\n2) Click Setup. Setup is complete when the button returns to its original colour.\n\n2) Click go. The model will run for 5 ticks. Afterwards you may click Export_To_Shapefile to export data for processing in a GIS.
14
0.0
1

TEXTBOX
10
12
741
42
Mobility, Ethnicity, and Language-Based Immigrant Settlement
25
0.0
1

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
  <experiment name="DN20,NB10-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DN20,NB5-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DN10,NB5-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DN10,NB10-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DN15,NB10-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DN15,NB5-" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>Export_BehaviorSpace</final>
    <timeLimit steps="1"/>
    <enumeratedValueSet variable="nbBus">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired_neighbors">
      <value value="15"/>
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
