<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:tdl="whatever"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">

    <xsl:output method="text"/>

    <xsl:variable name="input" as="xs:string +"
        select="unparsed-text-lines('input.txt')"/>

    <xsl:variable name="graph" as="map(*)" select="tdl:build-graph()"/>

    <xsl:variable name="height" as="xs:integer" select="count($input)"/>

    <xsl:variable name="width" as="xs:integer" select="string-length($input[1])"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="shortest-path" as="xs:string +" select="tdl:a-star()"/>

        <xsl:sequence select="($shortest-path ! ('(' || . || ')')) => string-join(' -> ')"/>
    </xsl:template>

    <xsl:function name="tdl:a-star" as="xs:string +">
        <xsl:sequence select="tdl:_a-star(  map { '1,1': ()},
                                            map {},
                                            map:put(tdl:initial-score-map(), '1,1', 0),
                                            tdl:put-f-score(tdl:initial-score-map(), '1,1', tdl:heuristic('1,1')))"/>
    </xsl:function>

    <xsl:function name="tdl:_a-star" as="xs:string +">
        <xsl:param name="open-set" as="map(*)"/>
        <xsl:param name="came-from" as="map(*)"/>
        <xsl:param name="g-score" as="map(*)"/>
        <xsl:param name="f-score" as="map(*)"/>

        <xsl:variable name="current" as="xs:string" select="$f-score('lowest')"/>
        
        <xsl:choose>
            <xsl:when test="$current eq ($width || ',' || $height)">
                <xsl:sequence select="tdl:reconstruct-path($came-from, $current)"/>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="neighbors" as="xs:string +" select="$graph($current)?neighbors"/>

                <xsl:variable name="scored-neighbors" as="map(*)"
                    select="let $scores := fold-left($neighbors, map {}, function ($map, $neighbor) { map:put($map, $neighbor, $g-score($current) + $graph($neighbor)?cost) } )
                            return map:remove($scores, map:keys($scores)[$scores(.) ge $g-score(.)])
                "/>

                <xsl:variable name="updated-open-set" as="map(*)"
                    select="fold-left(map:keys($scored-neighbors), map:remove($open-set, $current), function ($map, $neighbor) { map:put($map, $neighbor, ()) } )"/>

                <xsl:variable name="updated-came-from" as="map(*)"
                    select="fold-left(map:keys($scored-neighbors), $came-from, function ($map, $neighbor) { map:put($map, $neighbor, $current) } )"/>

                <xsl:variable name="updated-g-score" as="map(*)"
                    select="fold-left(map:keys($scored-neighbors), $g-score, function ($map, $neighbor) { map:put($map, $neighbor, $scored-neighbors($neighbor)) } )"/>

                <xsl:variable name="updated-f-score" as="map(*)"
                    select="fold-left(map:keys($scored-neighbors), $f-score, function ($map, $neighbor) { tdl:put-f-score($map, $neighbor, $scored-neighbors($neighbor) + tdl:heuristic($neighbor)) } )"/>

                <xsl:sequence select="tdl:_a-star($updated-open-set, $updated-came-from, $updated-g-score, $updated-f-score)"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:function name="tdl:reconstruct-path" as="xs:string +">
        <xsl:param name="came-from" as="map(*)"/>
        <xsl:param name="node" as="xs:string"/>

        <xsl:sequence select="tdl:_reconstruct-path($came-from, $node, $node)"/>
    </xsl:function>

    <xsl:function name="tdl:_reconstruct-path" as="xs:string +">
        <xsl:param name="came-from" as="map(*)"/>
        <xsl:param name="current" as="xs:string ?"/>
        <xsl:param name="path" as="xs:string *"/>

        <xsl:choose>
            <xsl:when test="not($current = map:keys($came-from))">
                <xsl:sequence select="$path"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="tdl:_reconstruct-path($came-from, $came-from($current), ($current, $path))"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:function name="tdl:heuristic" as="xs:integer">
        <xsl:param name="node" as="xs:string"/>
        
        <xsl:sequence select="
            let $x := $node => substring-before(',') => xs:integer(),
                $y := $node => substring-after(',') => xs:integer()
            return    abs($x - $width) + abs($y - $height)
        "/>
    </xsl:function>

    <xsl:function name="tdl:initial-score-map" as="map(*)">
        
        <xsl:sequence select="map:merge(
            ( map {'lowest': ()},
            for     $x in 1 to $width,
                    $y in 1 to $height
            return  map:entry($x || ',' || $y, xs:double('INF')))
        )"/>
    </xsl:function>

    <xsl:function name="tdl:put-f-score" as="map(*)">
        <xsl:param name="f-scores" as="map(*)"/>
        <xsl:param name="node" as="xs:string"/>
        <xsl:param name="score" as="xs:double"/>

        <xsl:variable name="updated" as="map(*)" select="map:put($f-scores, $node, $score)"/>
        <xsl:variable name="lowest-score" as="xs:double ?" select="if ($f-scores?lowest) then $f-scores($f-scores?lowest) else ()"/>

        <xsl:choose>
            <xsl:when test="not($lowest-score) or $score lt $lowest-score">
                <xsl:sequence select="map:put($updated, 'lowest', $node)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$updated"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>


    <xsl:function name="tdl:find-shortest-path" as="map(*)">
        <xsl:sequence select="tdl:_find-shortest-path('1,1', map { '1,1': map { 'distance': 0, 'path': '1,1' } }, ())"/>
    </xsl:function>

    <xsl:function name="tdl:_find-shortest-path" as="map(*)">
        <xsl:param name="curr-node" as="xs:string"/>
        <xsl:param name="paths" as="map(*)"/>
        <xsl:param name="visited" as="xs:string *"/>

        <xsl:choose>
            <xsl:when test="$curr-node eq ($width || ',' || $height)">
                <xsl:sequence select="$paths($curr-node)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="curr-path" as="map(*)" select="$paths($curr-node)"/>
                <xsl:variable name="unvisited-neighbors" as="xs:string *"
                    select="$graph($curr-node)?neighbors[not(. = $visited)]"/>

                <xsl:variable name="new-paths" as="map(*)"
                    select="fold-left($unvisited-neighbors, $paths,
                        function($paths-acc, $neighbor) {
                            let $old-path := $paths($neighbor),
                                $new-path := map { 'distance': $curr-path?distance + $graph($neighbor)?cost,
                                                   'path'    : ($curr-path?path, $neighbor)}
                            return  if (not(exists($old-path)) or ($old-path?distance gt $new-path?distance))
                                    then map:put($paths-acc, $neighbor, $new-path)
                                    else $paths-acc
                        })"/>
                
                <xsl:variable name="new-visited" as="xs:string +"
                    select="$visited, $curr-node"/>

                <xsl:sequence
                    select="tdl:_find-shortest-path(
                                tdl:next-smallest-path($new-paths, $new-visited),
                                $new-paths,
                                $new-visited)"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:function name="tdl:next-smallest-path" as="xs:string">
        <xsl:param name="paths" as="map(*)"/>
        <xsl:param name="visited" as="xs:string *"/>
        
        <xsl:sequence
            select="let $sort-func := function($key) { $paths($key)?distance },
                        $unvisited := map:keys($paths)[not(. = $visited)]
                    return sort($unvisited, (), $sort-func)[1]"/>
    </xsl:function>

    <xsl:function name="tdl:build-graph" as="map(*)">
        <xsl:map>
            <xsl:for-each select="1 to $height">
                <xsl:variable name="y" as="xs:integer" select="."/>

                <xsl:for-each select="1 to $width">
                    <xsl:variable name="x" as="xs:integer" select="."/>
                    <xsl:variable name="cost" as="xs:integer"
                        select="xs:integer(substring($input[$y], $x, 1))"/>
                    
                    <xsl:map-entry key="$x || ',' || $y"
                        select="map {
                            'cost': $cost,
                            'neighbors': tdl:neighbors($x, $y)
                        }"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:map>
    </xsl:function>

    <xsl:function name="tdl:neighbors" as="xs:string +">
        <xsl:param name="x" as="xs:integer"/>
        <xsl:param name="y" as="xs:integer"/>

        <xsl:if test="$x gt 1">
            <xsl:sequence select="($x - 1) || ',' || $y"/>
        </xsl:if>
        <xsl:if test="$x lt $width">
            <xsl:sequence select="($x + 1) || ',' || $y"/>
        </xsl:if>
        <xsl:if test="$y gt 1">
            <xsl:sequence select="$x || ',' || ($y - 1)"/>
        </xsl:if>
        <xsl:if test="$y lt $height">
            <xsl:sequence select="$x || ',' || ($y + 1)"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>