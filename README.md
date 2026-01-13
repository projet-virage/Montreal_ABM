# Montreal_ABM
Household Mobility on Montreal Island Considering Socio-Economic Attributes and Urban Structure

This prototype model, implemented in NetLogo, simulates the movement of households across Montreal Island, treating each household as an individual agent. It is based on the article _From Agent-Based Modeling to Urban Policy Strategy: Census-Validated Insights into
Immigrant Settlement and Diversity in Metro Vancouver_, to be published.

 The model incorporates multiple socio-economic variables to explore how households select residential locations based on both their socio-economic profiles and the urban environment. Specifically, household agents evaluate potential residential locations according to four criteria: 
 
 1. whether the average monthly rent falls below a certain proportion of their household income; 
 2. for households with children, whether the location is sufficiently close to schools;
 3. the accessibility of public transportation; 
 4. the proximity of parks and commercial amenities within the neighborhood. 
 
 Agents continue relocating until all four criteria are satisfied, with a maximum occupancy of 13 households per location to prevent overcrowding and ensure realistic representation of housing densities.

![Fig 1: NetLogo initializing ABM](resources\NL_Mtl_init.PNG)
_Fig 1: Initializing Montréal ABM in NetLogo_

![Fig 2: NetLogo running ABM](resources\NL_Mtl_run.PNG)
_Fig 2: Running Montréal ABM in NetLogo_

