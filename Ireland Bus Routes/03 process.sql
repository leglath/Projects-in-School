DROP TABLE IF EXISTS nondubroutes CASCADE;

CREATE TABLE nondubroutes AS 
(WITH nondubroutes AS 
(WITH dublin AS 
 (SELECT geom FROM counties 
  WHERE (name_tag like 'Dublin')
 ) 
 SELECT r.lngeom FROM route r, dublin 
 WHERE (NOT ST_CONTAINS(dublin.geom, ST_EndPoint(r.lngeom))) 
 AND (NOT ST_CONTAINS(dublin.geom, ST_StartPoint(r.lngeom)))
) 
SELECT c.name_tag AS name, COUNT(nondubroutes.lngeom) AS num_bus_routes 
FROM counties c 
LEFT JOIN nondubroutes ON ST_Intersects(c.geom, nondubroutes.lngeom)
GROUP BY c.name_tag
); 

SELECT * FROM nondubroutes ORDER BY num_bus_routes DESC;

DROP TABLE IF EXISTS res CASCADE;

CREATE TABLE res AS
(SELECT * FROM nondubroutes 
JOIN counties ON (nondubroutes.name = counties.name_tag));

