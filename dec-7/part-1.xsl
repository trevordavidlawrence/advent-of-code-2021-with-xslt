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

    <xsl:variable name="input" as="xs:string"
        select="unparsed-text-lines('input.txt')[1]"/>

    <xsl:variable name="positions" as="xs:integer +"
        select="tokenize($input, ',') ! xs:integer(.)"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="candidates" as="map(*) +">
            <xsl:for-each select="min($positions) to max($positions)">
                <xsl:variable name="dest-position" select="."/>

                <xsl:sequence select="
                    map {
                        'position': $dest-position,
                        'fuel': sum($positions ! abs($dest-position - .))
                    }
                "/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:sequence select="sort($candidates, (), 
            function($item) {$item?fuel})[1]?fuel"/>
    </xsl:template>

</xsl:stylesheet>