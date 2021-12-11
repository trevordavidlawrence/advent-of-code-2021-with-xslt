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
    <xsl:mode name="depth" on-no-match="deep-skip"/>
    <xsl:mode name="hpos" on-no-match="deep-skip"/>

    <xsl:variable name="commands" as="xs:string +" select="unparsed-text-lines('input.txt')"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="depth-changes" as="xs:integer +">
            <xsl:apply-templates select="$commands" mode="depth"/>
        </xsl:variable>

        <xsl:variable name="hpos-changes" as="xs:integer +">
            <xsl:apply-templates select="$commands" mode="hpos"/>
        </xsl:variable>

        <xsl:sequence select="sum($depth-changes) * sum($hpos-changes)"/>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'down')]" mode="depth" as="xs:integer">
        <xsl:sequence select=". => substring-after(' ') => xs:integer()"/>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'up')]" mode="depth" as="xs:integer">
        <xsl:sequence select="- (. => substring-after(' ') => xs:integer())"/>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'forward')]" mode="hpos" as="xs:integer">
        <xsl:sequence select=". => substring-after(' ') => xs:integer()"/>
    </xsl:template>
    

</xsl:stylesheet>