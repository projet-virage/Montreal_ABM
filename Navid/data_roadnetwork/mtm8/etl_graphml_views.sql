create index on public.node (node_id);


/* Check if protected bikelane exists in street */
create view edge_w_blane as 
with b as
(
	select geom,
		st_buffer(geom, 10, 'endcap=flat join=round') geom_buf
	from blane
	where typevoie like 'Piste cyclable%'
),
ewb as (
	select e.*
		,st_length(st_intersection(e.geom, b.geom_buf)) / st_length(e.geom) ratio
		,case when (st_length(st_intersection(e.geom, b.geom_buf)) / st_length(e.geom) > .9) then 1 else 0 end is_bikelane
	from edge as e
	left join b on st_dwithin(e.geom, b.geom, 10)
)
select distinct rds_id, street, carto, oneway, fromnode, tonode, round(st_length(geom)) street_length
	,first_value(is_bikelane) over (partition by rds_id order by ratio desc) is_bikelane
	,geom
from ewb;

/* Format street nodes to match Navid's NetLogo environment: 771 x 451 patches */
create or replace view node_nlogo_navid as 
with transfo as
(
	select -(st_xmin(bb) + st_xmax(bb)) / 2 delta_x,
		-(st_ymin(bb) + st_ymax(bb)) / 2 delta_y,
		771 / (st_xmax(bb) - st_xmin(bb)) factor_x,
		451 / (st_ymax(bb) - st_ymin(bb)) factor_y
	from (select st_extent(geom) bb from node) foo
)
select row_number() over() - 1 AS who,
	node_id,
	st_x(ST_TransScale(geom, delta_x, delta_y, factor_x, factor_y)) xcor,
	st_y(ST_TransScale(geom, delta_x, delta_y, factor_x, factor_y)) ycor,
	geom
from node, transfo;

/* testing the Netlogo GraphML stuff on small subset */
create or replace view edge_test as 
with seed as (
	select geom from edge where rds_id = 9881096
)
select e.* from public.edge_w_blane e
inner join seed s on st_dwithin(s.geom, e.geom, 100);

create or replace view node_test as 
with node_fid as
(
	select fromnode as node_id from public.edge_test
	union
	select tonode as node_id from public.edge_test
),
subset as (
	select * from node
	inner join node_fid using (node_id)
),
transfo as
(
	select -(st_xmin(bb) + st_xmax(bb)) / 2 delta_x,
		-(st_ymin(bb) + st_ymax(bb)) / 2 delta_y,
		33 / (st_xmax(bb) - st_xmin(bb)) factor_x,
		33 / (st_ymax(bb) - st_ymin(bb)) factor_y
	from (select st_extent(geom) bb from subset) foo
)
select row_number() over() - 1 AS who,
	node_id,
	st_x(ST_TransScale(geom, delta_x, delta_y, factor_x, factor_y)) xcor,
	st_y(ST_TransScale(geom, delta_x, delta_y, factor_x, factor_y)) ycor,
	geom
from subset, transfo;

create or replace view graphml_test as
with xmlnodes as (
select xmlagg(
	xmlelement(name node,
		xmlattributes('node '||who as id),
		xmlconcat(
			xmlelement(name data, xmlattributes('XCOR' as key), xcor),
			xmlelement(name data, xmlattributes('YCOR' as key), ycor),
			xmlelement(name data, xmlattributes('NODE_ID' as key), node_id),
			xmlelement(name data, xmlattributes('BREED' as key), 'nodes'),
			xmlelement(name data, xmlattributes('WHO' as key), who)
		)) order by who) as nodes
from node_test
),
xmlstreets as (
select xmlagg(xmlelement(name edge, 
	xmlattributes('node '||fn.who as source, 'node '||tn.who as target),
		xmlconcat(
			xmlelement(name data, xmlattributes('END1' as key), '(node '||fn.who||')'),
			xmlelement(name data, xmlattributes('END2' as key), '(node '||tn.who||')'),
			xmlelement(name data, xmlattributes('BREED' as key), 'edges'),
			xmlelement(name data, xmlattributes('FROM_NODE' as key), fromnode),
			xmlelement(name data, xmlattributes('TO_NODE' as key), tonode),
			xmlelement(name data, xmlattributes('STREET_LEN' as key), street_length),
			xmlelement(name data, xmlattributes('IS_BIKELANE' as key), is_bikelane::bool)
		))
	) as streets
from edge_test e
inner join node_test fn on fn.node_id=e.fromnode
inner join node_test tn on tn.node_id=e.tonode
)
select xmlserialize(document xmlconcat('<?xml version="1.0" encoding="UTF-8"?>'::xml, 
	xmlelement(name graphml,
		xmlattributes('http://graphml.graphdrawing.org/xmlns/graphml' as xmlns,
			'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
			'http://graphml.graphdrawing.org/xmlns/graphml' as "xsi:schemaLocation"),
		$$<key id="YCOR" for="node" attr.name="YCOR" attr.type="double"/>
		<key id="HIDDEN?" for="node" attr.name="HIDDEN?" attr.type="boolean"/>
		<key id="XCOR" for="node" attr.name="XCOR" attr.type="double"/>
		<key id="SIZE" for="node" attr.name="SIZE" attr.type="double"/>
		<key id="NODE_ID" for="node" attr.name="NODE_ID" attr.type="double"/>
		<key id="HEADING" for="node" attr.name="HEADING" attr.type="double"/>
		<key id="SHAPE" for="node" attr.name="SHAPE" attr.type="string"/>
		<key id="LABEL-COLOR" for="node" attr.name="LABEL-COLOR" attr.type="double"/>
		<key id="PEN-SIZE" for="node" attr.name="PEN-SIZE" attr.type="double"/>
		<key id="PEN-MODE" for="node" attr.name="PEN-MODE" attr.type="string"/>
		<key id="COLOR" for="node" attr.name="COLOR" attr.type="double"/>
		<key id="LABEL" for="node" attr.name="LABEL" attr.type="string"/>
		<key id="BREED" for="node" attr.name="BREED" attr.type="string"/>
		<key id="WHO" for="node" attr.name="WHO" attr.type="double"/>
		<key id="SHAPE" for="edge" attr.name="SHAPE" attr.type="string"/>
		<key id="LABEL-COLOR" for="edge" attr.name="LABEL-COLOR" attr.type="double"/>
		<key id="HIDDEN?" for="edge" attr.name="HIDDEN?" attr.type="boolean"/>
		<key id="END1" for="edge" attr.name="END1" attr.type="string"/>
		<key id="COLOR" for="edge" attr.name="COLOR" attr.type="double"/>
		<key id="TIE-MODE" for="edge" attr.name="TIE-MODE" attr.type="string"/>
		<key id="END2" for="edge" attr.name="END2" attr.type="string"/>
		<key id="LABEL" for="edge" attr.name="LABEL" attr.type="string"/>
		<key id="BREED" for="edge" attr.name="BREED" attr.type="string"/>
		<key id="THICKNESS" for="edge" attr.name="THICKNESS" attr.type="double"/>
		<key id="FROM_NODE" for="edge" attr.name="FROM_NODE" attr.type="double"/>
		<key id="TO_NODE" for="edge" attr.name="TO_NODE" attr.type="double"/>
		<key id="STREET_LEN" for="edge" attr.name="STREET_LEN" attr.type="double"/>
  		<key id="IS_BIKELANE" for="edge" attr.name="IS_BIKELANE" attr.type="boolean"/>$$::xml,
		xmlelement(name graph, xmlattributes('directed' as edgedefault), nodes, streets)
)) as text indent)
from xmlnodes, xmlstreets;

/* Full graphML data */
create materialized view graphml as
with xmlnodes as (
select xmlagg(
	xmlelement(name node,
		xmlattributes('node '||who as id),
		xmlconcat(
			xmlelement(name data, xmlattributes('XCOR' as key), xcor),
			xmlelement(name data, xmlattributes('YCOR' as key), ycor),
			xmlelement(name data, xmlattributes('NODE_ID' as key), node_id),
			xmlelement(name data, xmlattributes('BREED' as key), 'nodes'),
			xmlelement(name data, xmlattributes('WHO' as key), who)
		)) order by who) as nodes
from node_nlogo_navid
),
xmlstreets as (
select xmlagg(xmlelement(name edge, 
	xmlattributes('node '||fn.who as source, 'node '||tn.who as target),
		xmlconcat(
			xmlelement(name data, xmlattributes('END1' as key), '(node '||fn.who||')'),
			xmlelement(name data, xmlattributes('END2' as key), '(node '||tn.who||')'),
			xmlelement(name data, xmlattributes('BREED' as key), 'links'),
			xmlelement(name data, xmlattributes('STREET_LEN' as key), street_length),
			xmlelement(name data, xmlattributes('IS_BIKELANE' as key), is_bikelane::bool)
		))
	) as streets
from edge_w_blane e
inner join node_nlogo_navid fn on fn.node_id=e.fromnode
inner join node_nlogo_navid tn on tn.node_id=e.tonode
),
xmlstreets_reverse as (
-- directed links need to account for bidirectional streets
select xmlagg(xmlelement(name edge, 
	xmlattributes('node '||fn.who as source, 'node '||tn.who as target),
		xmlconcat(
			xmlelement(name data, xmlattributes('END1' as key), '(node '||fn.who||')'),
			xmlelement(name data, xmlattributes('END2' as key), '(node '||tn.who||')'),
			xmlelement(name data, xmlattributes('BREED' as key), 'edges'),
			xmlelement(name data, xmlattributes('FROM_NODE' as key), fromnode),
			xmlelement(name data, xmlattributes('TO_NODE' as key), tonode),
			xmlelement(name data, xmlattributes('STREET_LEN' as key), street_length),
			xmlelement(name data, xmlattributes('IS_BIKELANE' as key), is_bikelane::bool)
		))
	) as streets_rev
from edge_w_blane e
inner join node_nlogo_navid fn on fn.node_id=e.tonode
inner join node_nlogo_navid tn on tn.node_id=e.fromnode
where oneway = 0
)
select xmlconcat('<?xml version="1.0" encoding="UTF-8"?>'::xml, 
	xmlelement(name graphml,
		xmlattributes('http://graphml.graphdrawing.org/xmlns/graphml' as xmlns,
			'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
			'http://graphml.graphdrawing.org/xmlns/graphml' as "xsi:schemaLocation"),
		$$<key id="YCOR" for="node" attr.name="YCOR" attr.type="double"/>
		<key id="HIDDEN?" for="node" attr.name="HIDDEN?" attr.type="boolean"/>
		<key id="XCOR" for="node" attr.name="XCOR" attr.type="double"/>
		<key id="SIZE" for="node" attr.name="SIZE" attr.type="double"/>
		<key id="NODE_ID" for="node" attr.name="NODE_ID" attr.type="double"/>
		<key id="HEADING" for="node" attr.name="HEADING" attr.type="double"/>
		<key id="SHAPE" for="node" attr.name="SHAPE" attr.type="string"/>
		<key id="LABEL-COLOR" for="node" attr.name="LABEL-COLOR" attr.type="double"/>
		<key id="PEN-SIZE" for="node" attr.name="PEN-SIZE" attr.type="double"/>
		<key id="PEN-MODE" for="node" attr.name="PEN-MODE" attr.type="string"/>
		<key id="COLOR" for="node" attr.name="COLOR" attr.type="double"/>
		<key id="LABEL" for="node" attr.name="LABEL" attr.type="string"/>
		<key id="BREED" for="node" attr.name="BREED" attr.type="string"/>
		<key id="WHO" for="node" attr.name="WHO" attr.type="double"/>
		<key id="SHAPE" for="edge" attr.name="SHAPE" attr.type="string"/>
		<key id="LABEL-COLOR" for="edge" attr.name="LABEL-COLOR" attr.type="double"/>
		<key id="HIDDEN?" for="edge" attr.name="HIDDEN?" attr.type="boolean"/>
		<key id="END1" for="edge" attr.name="END1" attr.type="string"/>
		<key id="COLOR" for="edge" attr.name="COLOR" attr.type="double"/>
		<key id="TIE-MODE" for="edge" attr.name="TIE-MODE" attr.type="string"/>
		<key id="END2" for="edge" attr.name="END2" attr.type="string"/>
		<key id="LABEL" for="edge" attr.name="LABEL" attr.type="string"/>
		<key id="BREED" for="edge" attr.name="BREED" attr.type="string"/>
		<key id="THICKNESS" for="edge" attr.name="THICKNESS" attr.type="double"/>
		<key id="FROM_NODE" for="edge" attr.name="FROM_NODE" attr.type="double"/>
		<key id="TO_NODE" for="edge" attr.name="TO_NODE" attr.type="double"/>
		<key id="STREET_LEN" for="edge" attr.name="STREET_LEN" attr.type="double"/>
  		<key id="IS_BIKELANE" for="edge" attr.name="IS_BIKELANE" attr.type="boolean"/>$$::xml,
		xmlelement(name graph, xmlattributes('directed' as edgedefault), nodes, streets, streets_rev)
))
from xmlnodes, xmlstreets, xmlstreets_reverse;
