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

    <xsl:variable name="split-point" as="xs:integer" select="index-of($input, '')"/>

    <xsl:variable name="initial-points" as="map(xs:string, xs:integer) +"
        select="$input[position() lt $split-point] ! tdl:parse-point(.)"/>

    <xsl:variable name="folds" as="map(*) +"
        select="$input[position() gt $split-point] ! tdl:parse-fold(.)"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:variable name="initial-sheet" as="map(*)">
            <xsl:map>
                <xsl:for-each select="$initial-points">
                    <xsl:map-entry key="tdl:point-key(.)"
                        select="."/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>

        <xsl:sequence select="count(map:keys(tdl:fold($initial-sheet, $folds[1])))"/>

    </xsl:template>

    <xsl:function name="tdl:fold" as="map(*)">
        <xsl:param name="sheet" as="map(*)"/>
        <xsl:param name="fold" as="map(*)"/>

        <xsl:variable name="affected-points" as="map(*) *"
                    select="(map:keys($sheet) ! $sheet(.))[tdl:affected-by-fold(., $fold)]"/>
                
        <xsl:variable name="reduced-sheet" as="map(*)"
            select="fold-left($affected-points, $sheet,
                        function ($sheet-acc, $point)
                            { map:remove($sheet-acc, tdl:point-key($point)) })"/>
        
        <xsl:variable name="incoming-sheet" as="map(*)"
            select="map:merge(
                        $affected-points !  (let $new-point := tdl:reflect(., $fold)
                                            return map { tdl:point-key($new-point): $new-point }))"/>

        <xsl:sequence select="map:merge(($reduced-sheet, $incoming-sheet))"/>
    </xsl:function>

    
    <xsl:function name="tdl:reflect" as="map(*)">
        <xsl:param name="point" as="map(*)"/>
        <xsl:param name="fold" as="map(*)"/>
        
        <xsl:sequence
            select="if ($fold?axis eq 'x')
                        then map { 'x': ($fold?value - ($point?x - $fold?value)), 'y': $point?y }
                        else map { 'x': $point?x, 'y': ($fold?value - ($point?y - $fold?value)) }"/>
    </xsl:function>

    <xsl:function name="tdl:affected-by-fold" as="xs:boolean">
        <xsl:param name="point" as="map(*)"/>
        <xsl:param name="fold" as="map(*)"/>
        
        <xsl:choose>
            <xsl:when test="$fold?axis eq 'x'">
                <xsl:sequence select="$point?x gt $fold?value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$point?y gt $fold?value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tdl:point-key" as="xs:string">
        <xsl:param name="point" as="map(*)"/>

        <xsl:sequence select="$point?x || ',' || $point?y"/>
    </xsl:function>

    <xsl:function name="tdl:parse-point" as="map(*)">
        <xsl:param name="point" as="xs:string"/>

        <xsl:sequence
            select="map {
                        'x': xs:integer(substring-before($point, ',')),
                        'y': xs:integer(substring-after($point, ',')) }"/>
    </xsl:function>

    <xsl:function name="tdl:parse-fold" as="map(*)">
        <xsl:param name="fold" as="xs:string"/>

        <xsl:map>
            <xsl:analyze-string select="$fold" regex="^fold along ([xy])=(\d+)$">
                <xsl:matching-substring>
                    <xsl:map-entry key="'axis'" select="regex-group(1)"/>
                    <xsl:map-entry key="'value'" select="xs:integer(regex-group(2))"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:map>
    </xsl:function>

</xsl:stylesheet>