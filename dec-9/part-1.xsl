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
        <xsl:variable name="low-point-risks" as="xs:integer +">
            <xsl:for-each select="1 to array:size($heightmap)">
                <xsl:variable name="x" as="xs:integer" select="."/>

                <xsl:for-each select="1 to array:size($heightmap(.))">
                    <xsl:variable name="y" as="xs:integer" select="."/>

                    <xsl:if test="tdl:is-low-point($x, $y)">
                        <xsl:sequence select="$heightmap($x)($y) + 1"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <xsl:sequence select="sum($low-point-risks)"/>
    </xsl:template>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

    <xsl:function name="tdl:is-low-point" as="xs:boolean">
        <xsl:param name="x" as="xs:integer"/>
        <xsl:param name="y" as="xs:integer"/>

        <xsl:sequence select="
            let $height    := $heightmap($x)($y),
                $neighbors := tdl:neighbors($x, $y)
            return every $neighbor in $neighbors satisfies $neighbor gt $height"/>
    </xsl:function>

    <xsl:function name="tdl:neighbors" as="xs:integer +">
        <xsl:param name="x" as="xs:integer"/>
        <xsl:param name="y" as="xs:integer"/>


        <xsl:if test="$x gt 1">
            <xsl:sequence select="$heightmap($x - 1)($y)"/>
        </xsl:if>
        <xsl:if test="$x lt array:size($heightmap)">
            <xsl:sequence select="$heightmap($x + 1)($y)"/>
        </xsl:if>
        <xsl:if test="$y gt 1">
            <xsl:sequence select="$heightmap($x)($y - 1)"/>
        </xsl:if>
        <xsl:if test="$y lt array:size($heightmap(1))">
            <xsl:sequence select="$heightmap($x)($y + 1)"/>
        </xsl:if>

    </xsl:function>

</xsl:stylesheet>