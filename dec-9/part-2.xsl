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

    <xsl:variable name="heightmap" as="array(array(xs:integer))"
        select="array { $input ! array { tdl:split-string(.) ! xs:integer(.) } }"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:variable name="low-points" as="map(xs:string, xs:integer) +"
            select="tdl:find-low-points()"/>

        <xsl:variable name="basins" as="map(*) +"
            select="$low-points ! tdl:basin(.)"/>

        <xsl:sequence select="
            let $basin-sizes := ($basins ! count(.?points)) => sort() => reverse()

            return $basin-sizes[1] * $basin-sizes[2] * $basin-sizes[3]
        "/>
    </xsl:template>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

    <xsl:function name="tdl:basin" as="map(*)">
        <xsl:param name="low-point" as="map(xs:string, xs:integer)"/>
        
        <xsl:sequence select="map {
                'low-point': $low-point,
                'points': tdl:_basin($low-point)
            }"/>
    </xsl:function>

    <xsl:function name="tdl:_basin" as="map(xs:string, xs:integer) +">
        <xsl:param name="points" as="map(xs:string, xs:integer) +"/>

        <xsl:variable name="new-neighbors" as="map(xs:string, xs:integer) *"
            select="tdl:new-neighbors($points)"/>

        <xsl:choose>
            <xsl:when test="empty($new-neighbors)">
                <xsl:sequence select="$points"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="tdl:_basin(($points, $new-neighbors))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tdl:new-neighbors" as="map(xs:string, xs:integer) *">
        <xsl:param name="points" as="map(xs:string, xs:integer) +"/>

        <xsl:sequence
            select="tdl:distinct-maps($points ! tdl:neighbors(.)[not( tdl:height(.) eq 9)]
                                                                [not( some $other-point
                                                                      in $points
                                                                      satisfies deep-equal($other-point, .))])"/>
    </xsl:function>

    <xsl:function name="tdl:find-low-points" as="map(xs:string, xs:integer) +">
        <xsl:for-each select="1 to array:size($heightmap)">
                <xsl:variable name="x" as="xs:integer" select="."/>

                <xsl:for-each select="1 to array:size($heightmap(.))">
                    <xsl:variable name="y" as="xs:integer" select="."/>
                    <xsl:variable name="point" as="map(xs:string, xs:integer)"
                        select="map {'x': $x, 'y': $y}"/>

                    <xsl:if test="tdl:is-low-point($point)">
                        <xsl:sequence select="$point"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
    </xsl:function>

    <xsl:function name="tdl:is-low-point" as="xs:boolean">
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>

        <xsl:sequence select="
            let $height    := $heightmap($point?x)($point?y),
                $neighbors := tdl:neighbors($point) ! tdl:height(.)
            return every $neighbor in $neighbors satisfies $neighbor gt $height"/>
    </xsl:function>

    <xsl:function name="tdl:height" as="xs:integer">
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>

        <xsl:sequence select="$heightmap($point?x)($point?y)"/>
    </xsl:function>

    <xsl:function name="tdl:neighbors" as="map(xs:string, xs:integer) +">
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>

        <xsl:if test="$point?x gt 1">
            <xsl:sequence select="map {'x': $point?x - 1, 'y': $point?y}"/>
        </xsl:if>
        <xsl:if test="$point?x lt array:size($heightmap)">
            <xsl:sequence select="map {'x': $point?x + 1, 'y': $point?y}"/>
        </xsl:if>
        <xsl:if test="$point?y gt 1">
            <xsl:sequence select="map {'x': $point?x, 'y': $point?y - 1}"/>
        </xsl:if>
        <xsl:if test="$point?y lt array:size($heightmap(1))">
            <xsl:sequence select="map {'x': $point?x, 'y': $point?y + 1}"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="tdl:distinct-maps" as="map(*) *">
        <xsl:param name="maps" as="map(*) *"/>

        <xsl:for-each select="1 to count($maps)">
            <xsl:variable name="pos" as="xs:integer" select="."/>
            <xsl:variable name="map" as="map(*)" select="$maps[$pos]"/>

            <xsl:if test="every $other-map in $maps[position() gt $pos] satisfies not(deep-equal($map, $other-map))">
                <xsl:sequence select="$map"/>
            </xsl:if>
        </xsl:for-each>     
    </xsl:function>

</xsl:stylesheet>