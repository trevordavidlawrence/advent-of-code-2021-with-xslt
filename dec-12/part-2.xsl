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
    
    <xsl:template name="xsl:initial-template">
        <xsl:variable name="graph" as="map(*)" select="tdl:build-graph($input)"/>

        <xsl:variable name="paths" as="array(xs:string) +" select="tdl:paths($graph)"/>

        <xsl:for-each select="$paths">
            <xsl:sequence select="string-join(array:flatten(.), ',')"/>
            <xsl:sequence select="codepoints-to-string(10)"/>
        </xsl:for-each>

        <xsl:sequence select="count($paths)"/>
    </xsl:template>

    <xsl:function name="tdl:paths" as="array(xs:string) +">
        <xsl:param name="graph" as="map(*)"/>
        
        <xsl:sequence select="tdl:_paths($graph, (), false(), [], 'start')"/>
    </xsl:function>

    <xsl:function name="tdl:_paths" as="array(xs:string) *">
        <xsl:param name="graph" as="map(*)"/>
        <xsl:param name="visited-little-caves" as="xs:string *"/>
        <xsl:param name="bonus-cave-used" as="xs:boolean"/>
        <xsl:param name="path" as="array(xs:string)"/>
        <xsl:param name="cave" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$cave eq 'end'">
                <xsl:sequence select="array:append($path, $cave)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="valid-neighbors" as="xs:string *"
                    select="tdl:valid-neighbors($graph, $visited-little-caves, $bonus-cave-used, $cave)"/>

                <xsl:choose>
                    <xsl:when test="empty($valid-neighbors)">
                        <!-- Nowhere to go, this path dies on the vine -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="$valid-neighbors">
                            <xsl:variable name="next-cave" as="xs:string" select="."/>

                            <xsl:choose>
                                <xsl:when test="$next-cave = $visited-little-caves">
                                    <xsl:sequence
                                        select="tdl:_paths($graph, $visited-little-caves, true(),
                                            array:append($path, $cave), $next-cave)"/>
                                </xsl:when>
                                <xsl:when test="not($graph($next-cave)?big)">
                                    <xsl:sequence
                                        select="tdl:_paths($graph, ($visited-little-caves, $next-cave), $bonus-cave-used,
                                            array:append($path, $cave), $next-cave)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence
                                        select="tdl:_paths($graph, $visited-little-caves, $bonus-cave-used,
                                            array:append($path, $cave), $next-cave)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:function name="tdl:valid-neighbors" as="xs:string *">
        <xsl:param name="graph" as="map(*)"/>
        <xsl:param name="visited-little-caves" as="xs:string *"/>
        <xsl:param name="bonus-cave-used" as="xs:boolean"/>
        <xsl:param name="cave" as="xs:string"/>
        
        <xsl:sequence select="$graph($cave)?neighbors
                                [not(. eq 'start')]
                                [$graph(.)?big or not($bonus-cave-used) or not(. = $visited-little-caves)]"/>
    </xsl:function>

    <xsl:function name="tdl:build-graph" as="map(*)">
        <xsl:param name="input" as="xs:string +"/>

        <xsl:iterate select="$input ! tdl:parse-connection(.)">
            <xsl:param name="graph" as="map(*)" select="map {}"/>
            <xsl:on-completion select="$graph"/>

            <xsl:variable name="connection" as="map(*)" select="."/>
            
            <xsl:variable name="inverted-connection" as="map(*)"
                select="map { 'start': $connection?end, 'end': $connection?start }"/>

            <xsl:variable name="updated-graph" as="map(*)"
                select="fold-left(($connection, $inverted-connection), $graph, tdl:add-connection#2)"/>

            <xsl:next-iteration>
                <xsl:with-param name="graph" select="$updated-graph"/>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:function>

    <xsl:function name="tdl:add-connection" as="map(*)">
        <xsl:param name="graph" as="map(*)"/>
        <xsl:param name="connection" as="map(*)"/>
        
        <xsl:sequence
            select="map:put(
                        $graph,
                        $connection?start,
                        map {   'big': tdl:is-big-cave($connection?start),
                                'neighbors': ($graph($connection?start)?neighbors, $connection?end) })"/>
    </xsl:function>


    <xsl:function name="tdl:is-big-cave" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        
        <xsl:sequence select="matches($name, '[A-Z]')"/>
    </xsl:function>

    <xsl:function name="tdl:parse-connection" as="map(xs:string, xs:string)">
        <xsl:param name="connection" as="xs:string"/>
        
        <xsl:sequence select="
            map {
                'start': substring-before($connection, '-'), 
                'end': substring-after($connection, '-')
            }"/>
    </xsl:function>

</xsl:stylesheet>