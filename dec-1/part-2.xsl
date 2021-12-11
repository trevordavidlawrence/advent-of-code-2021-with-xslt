<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">

    <xsl:output method="text"/>

    <xsl:variable name="measurements" as="xs:integer +" select="unparsed-text-lines('input.txt')!xs:integer(.)"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="increases" as="xs:integer +">
            <xsl:iterate select="$measurements[position() ge 4]">
                <xsl:param name="last-sum" as="xs:integer" select="$measurements[1] + $measurements[2] + $measurements[3]"/>

                <xsl:param name="a" as="xs:integer" select="$measurements[2]"/>
                <xsl:param name="b" as="xs:integer" select="$measurements[3]"/>
                <xsl:variable name="c" as="xs:integer" select="."/>

                <xsl:variable name="current-sum" as="xs:integer" select="sum(($a, $b, $c))"/>

                <xsl:if test="$current-sum gt $last-sum">
                    <xsl:sequence select="."/>
                </xsl:if>

                <xsl:next-iteration>
                    <xsl:with-param name="last-sum" select="$current-sum"/>
                    <xsl:with-param name="a" select="$b"/>
                    <xsl:with-param name="b" select="$c"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:sequence select="count($increases)"/>
    </xsl:template>
    

</xsl:stylesheet>