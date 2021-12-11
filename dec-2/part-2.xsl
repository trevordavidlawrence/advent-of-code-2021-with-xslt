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
    <xsl:mode name="convert-to-xml" on-no-match="shallow-skip"/>
    <xsl:mode name="go" on-no-match="shallow-skip" use-accumulators="aim"/>

    <xsl:accumulator name="aim" as="xs:integer" initial-value="0">
        <xsl:accumulator-rule select="$value + xs:integer(.)" match="up | down"/>
    </xsl:accumulator>

    <xsl:variable name="commands" as="xs:string +" select="unparsed-text-lines('input.txt')"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="commands-xml">
            <commands>
                <xsl:apply-templates select="$commands" mode="convert-to-xml"/>
            </commands>
        </xsl:variable>

        <xsl:variable name="changes" as="map(xs:string, xs:integer)+">
            <xsl:apply-templates select="$commands-xml" mode="go"/>
        </xsl:variable>

        <xsl:sequence select="
            sum($changes!map:get(., 'hpos')) * sum($changes!map:get(., 'depth'))
        "/>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'down')]" mode="convert-to-xml">
        <down>{. => substring-after(' ')}</down>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'up')]" mode="convert-to-xml">
        <up>{- (. => substring-after(' ') => xs:integer())}</up>
    </xsl:template>

    <xsl:template match=".[starts-with(., 'forward')]" mode="convert-to-xml">
        <forward>{. => substring-after(' ')}</forward>
    </xsl:template>

    <xsl:template match="forward" mode="go" as="map(xs:string, xs:integer)">
        <xsl:variable name="value" as="xs:integer" select="xs:integer(.)"/>
        <xsl:sequence select="
            map {
                'hpos': $value,
                'depth': $value * accumulator-before('aim')
            }
        "/>
    </xsl:template>
    

</xsl:stylesheet>