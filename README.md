# Montreal_ABM
Household Mobility on Montreal Island Considering Socio-Economic Attributes and Urban Structure

The objective of this repo is to build a prototype to illustrate how ABM can be leveraged to simulate dynamic social phenomena to show to Virgae commeittee members who would be less knowldgeable of ABM and simulations.

A first prototype developed by Navid (Virage PDF) can be found in `.\Navid\`. A second one, based on Liliana's MELBIS model is stored unders `.\MELBIS\`.

## Navid's prototype

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

## MELBIS model

Based on the [published MELBIS, v2](https://www.comses.net/codebases/b4a18765-2f65-4010-b19f-b32dbc23d8a6/releases/1.1.0/), model.

_NB_ The original v2 model running on NetLogo 6.4.0 has been ported to NetLogo 7.0.3. See `MELBIS\code\MELBIS-V2.nlogox`.

## Navid's prototype, take 2

Follwoing discussions in the modelling workgroup, we decide to build a active transport ABM prototype. The prototype, developped by Navid, is based on the paper [_A high resolution agent-based model to support walk-bicycle infrastructure investment decisions: A case study with New York City_, Aziz et al., 2018](https://doi.org/10.1016/j.trc.2017.11.008). It should allow to test bike lane interventions.

One of the required dataset is the street network, with basic attributes (street length, existing bike lanes, etc.), in order to compute shortest path distances between home and work place for the agents. See `Navid\data_roadnetwork\mtm8\etl_graphml_views.sql` and `Navid\data_roadnetwork\mtm8\navid_streetnetwork.nlogox`.

_NB_ I thought one could save some time (and gain flexibility) by producing a GraphML in Postgresql (with nodes and edges) and import it directly in NetLogo. But the `who` variable, which is the agent primary key, is set more or less randomly by NL, and not following the nodes' order in the graphML document. This prevents the links to refer to the correct nodes once imported. A dead-end... 