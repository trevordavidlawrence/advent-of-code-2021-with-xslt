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
            <xsl:iterate select="$measurements[position() gt 1]">
                <xsl:param name="last" as="xs:integer" select="$measurements[1]"/>

                <xsl:if test=". gt $last">
                    <xsl:sequence select="."/>
                </xsl:if>

                <xsl:next-iteration>
                    <xsl:with-param name="last" select="."/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:sequence select="count($increases)"/>
    </xsl:template>
    

</xsl:stylesheet>