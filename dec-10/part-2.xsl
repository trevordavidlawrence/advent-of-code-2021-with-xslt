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

    <xsl:variable name="lines" as="xs:string +"
        select="unparsed-text-lines('input.txt')"/>

    <xsl:variable name="scores" as="map(xs:string, xs:integer)"
        select="
            map {
                ')': 1,
                ']': 2,
                '}': 3,
                codepoints-to-string(62): 4
            }"/>
    
    <xsl:variable name="opens" as="map(xs:string, xs:string)"
        select="map {
            '(': ')',
            '[': ']',
            '{': '}',
            codepoints-to-string(60): codepoints-to-string(62)
        }"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:sequence
            select="sort($lines ! tdl:auto-complete(.) ! tdl:score-completion(.))[position() eq ceiling(last() div 2)]"/>
    </xsl:template>

    <xsl:function name="tdl:auto-complete" as="xs:string ?">
        <xsl:param name="line" as="xs:string"/>

        <xsl:iterate select="tdl:split-string($line)">
            <xsl:param name="stack" as="xs:string *" select="()"/>
            <xsl:on-completion select="string-join($stack)"/>

            <xsl:choose>
                <xsl:when test=". = map:keys($opens)">
                    <xsl:next-iteration>
                        <xsl:with-param name="stack" select="$opens(.), $stack"/>
                    </xsl:next-iteration>
                </xsl:when>
                <xsl:when test=". = head($stack)">
                    <xsl:next-iteration>
                        <xsl:with-param name="stack" select="tail($stack)"/>
                    </xsl:next-iteration>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:break select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:iterate>
    </xsl:function>

    <xsl:function name="tdl:score-completion" as="xs:integer">
        <xsl:param name="completion-string" as="xs:string"/>

        <xsl:iterate select="tdl:split-string($completion-string)">
            <xsl:param name="score" as="xs:integer" select="0"/>
            <xsl:on-completion select="$score"/>

            <xsl:next-iteration>
                <xsl:with-param name="score" as="xs:integer" select="($score * 5) + $scores(.)"/>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>