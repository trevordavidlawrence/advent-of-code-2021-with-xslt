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

    <xsl:variable name="initial-fish" as="xs:integer +"
        select="tokenize($input, ',') ! xs:integer(.)"/>

    <xsl:template name="xsl:initial-template">

        <xsl:variable name="initial-population" as="map(xs:integer, xs:integer)">
            <xsl:map>
                <xsl:for-each select="0 to 8">
                    <xsl:map-entry key="." select="count($initial-fish[current() eq .])"/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>

        <xsl:variable name="final-population" as="map(xs:integer, xs:integer)">
            <xsl:iterate select="1 to 256">
                <xsl:param name="population" as="map(xs:integer, xs:integer)"
                    select="$initial-population"/>
                <xsl:on-completion select="$population"/>

                <xsl:next-iteration>
                    <xsl:with-param name="population" as="map(xs:integer, xs:integer)">
                        <xsl:map>
                            <xsl:for-each select="1 to 6, 8">
                                <xsl:map-entry key=". - 1" select="$population(.)"/>
                            </xsl:for-each>
                            <xsl:map-entry key="6" select="($population(0)) + ($population(7))"/>
                            <xsl:map-entry key="8" select="$population(0)"/>
                        </xsl:map>
                    </xsl:with-param>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:sequence select="sum(map:keys($final-population) ! $final-population(.))"/>
    </xsl:template>

</xsl:stylesheet>