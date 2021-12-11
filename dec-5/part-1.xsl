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

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="lines" as="map(*) +"
            select="($input ! tdl:parse-input(.))[tdl:is-horizontal-or-vertical(.)]"/>
        
        <xsl:variable name="points" as="map(*) +"
            select="$lines ! tdl:points(.)"/>

        <xsl:variable name="points-with-multiples" as="map(*) *">
            <xsl:for-each-group select="$points" composite="true"
                group-by=".?x, .?y">
                <xsl:if test="count(current-group()) gt 1">
                    <xsl:sequence select="."/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:variable>

        <xsl:sequence select="count($points-with-multiples)"/>
    </xsl:template>

    <xsl:function name="tdl:parse-input" as="map(*)">
        <xsl:param name="line" as="xs:string"/>

        <xsl:analyze-string select="$line"
            regex="^(\d+),(\d+) -> (\d+),(\d+)$">
            <xsl:matching-substring>
                <xsl:sequence select="
                map {
                    'x1': xs:integer(regex-group(1)),
                    'y1': xs:integer(regex-group(2)),
                    'x2': xs:integer(regex-group(3)),
                    'y2': xs:integer(regex-group(4))
                }"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="tdl:is-horizontal-or-vertical" as="xs:boolean">
        <xsl:param name="line" as="map(*)"/>

        <xsl:sequence select="($line?x1 eq $line?x2) or ($line?y1 eq $line?y2)"/>
    </xsl:function>

    <xsl:function name="tdl:points" as="map(*) +">
        <xsl:param name="line" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$line?x1 eq $line?x2">
                <xsl:for-each select="min(($line?y1, $line?y2)) to max(($line?y1, $line?y2))">
                    <xsl:sequence select="
                        map {
                            'x': $line?x1,
                            'y': .
                        }
                    "/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="min(($line?x1, $line?x2)) to max(($line?x1, $line?x2))">
                    <xsl:sequence select="
                        map {
                            'x': .,
                            'y': $line?y1
                        }
                    "/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>