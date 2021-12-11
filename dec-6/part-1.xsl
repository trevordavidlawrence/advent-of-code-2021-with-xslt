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

        <xsl:variable name="final-population" as="xs:integer +">
            <xsl:iterate select="1 to 80">
                <xsl:param name="population" as="xs:integer +" select="$initial-fish"/>
                <xsl:on-completion select="$population"/>

                <xsl:next-iteration>
                    <xsl:with-param name="population" as="xs:integer +">
                        <xsl:apply-templates select="$population"/>
                    </xsl:with-param>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:sequence select="count($final-population)"/>
    </xsl:template>

    <xsl:template match=".[. instance of xs:integer]" as="xs:integer +">
        <xsl:choose>
            <xsl:when test=". eq 0">
                <xsl:sequence select="6"/>
                <xsl:sequence select="8"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select=". - 1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>