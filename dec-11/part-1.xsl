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

    <xsl:variable name="initial-board" as="array(array(xs:integer))" select="tdl:parse-board($input)"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:iterate select="1 to 100">
            <xsl:param name="board" as="array(array(xs:integer))" select="$initial-board"/>
            <xsl:param name="flashes" as="xs:integer" select="0"/>
            <xsl:on-completion select="$flashes"/>

            <xsl:variable name="step-results" as="map(*)" select="tdl:step($board)"/>

            <xsl:next-iteration>
                <xsl:with-param name="board" select="$step-results?board"/>
                <xsl:with-param name="flashes" select="$flashes + $step-results?flashes"/>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:template>

    <xsl:function name="tdl:step" as="map(*)">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        
        <xsl:variable name="stepped-board" as="array(array(xs:integer))"
            select="tdl:_step(tdl:increment-board($board))"/>

        <xsl:sequence select="
            map {
                'board': $stepped-board,
                'flashes': tdl:count-flashers($stepped-board)
            }"/>
    </xsl:function>

    <xsl:function name="tdl:_step" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        
        <xsl:variable name="next-flasher" as="map(xs:string, xs:integer) ?"
            select="tdl:find-next-flasher($board)"/>

        <xsl:choose>
            <xsl:when test="not(exists($next-flasher))">
                <xsl:sequence select="$board"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="
                    let $zeroed-board := tdl:set-point($board, $next-flasher, 0),
                        $post-flash-board := tdl:flash($zeroed-board, $next-flasher)
                    return tdl:_step($post-flash-board)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tdl:flash" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        <xsl:param name="flasher" as="map(xs:string, xs:integer)"/>

        <xsl:sequence select="
            let $neighbors := tdl:neighbors($flasher)
            return
                fold-left($neighbors, $board,
                    function($_board, $point) {
                        let $val := $_board($point?x)($point?y)
                        return  if ($val gt 0)
                                    then tdl:set-point($_board, $point, $val + 1)
                                    else $_board
                })"/>
    </xsl:function>

    <xsl:function name="tdl:increment-board" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        
        <xsl:sequence select="tdl:apply($board, function($x, $y, $val) { $val + 1 })"/>
    </xsl:function>

    <xsl:function name="tdl:apply" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        <xsl:param name="func" as="function(xs:integer, xs:integer, xs:integer) as xs:integer"/>
        
        <xsl:sequence select="
            array {
                for $x in (1 to array:size($board))
                return array {
                    for $y in (1 to array:size($board(1)))
                    return $func($x, $y, $board($x)($y))
                }
            }
        "/>
    </xsl:function>

    <xsl:function name="tdl:set-point" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>
        <xsl:param name="val" as="xs:integer"/>

        <xsl:sequence select="tdl:apply-to-point($board, $point, function($_) { $val })"/>
    </xsl:function>

    <xsl:function name="tdl:apply-to-point" as="array(array(xs:integer))">
        <xsl:param name="board" as="array(array(xs:integer))"/>
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>
        <xsl:param name="func" as="function(xs:integer) as xs:integer"/>

        <xsl:sequence select="tdl:apply($board, function($x, $y, $val) {
            if ($x eq $point?x and $y eq $point?y) then $func($val) else $val
        })"/>
    </xsl:function>

    <xsl:function name="tdl:find-next-flasher" as="map(xs:string, xs:integer) ?">
        <xsl:param name="board" as="array(array(xs:integer))"/>

        <xsl:iterate select="1 to array:size($board)">
            <xsl:variable name="x" as="xs:integer" select="."/>

            <xsl:variable name="flasher" as="map(xs:string, xs:integer) ?">
                <xsl:iterate select="1 to array:size($board($x))">
                    <xsl:variable name="y" as="xs:integer" select="."/>

                    <xsl:if test="$board($x)($y) gt 9">
                        <xsl:break select="map {'x': $x, 'y': $y}"/>
                    </xsl:if>
                </xsl:iterate>
            </xsl:variable>
            
            <xsl:if test="exists($flasher)">
                <xsl:break select="$flasher"/>
            </xsl:if>
        </xsl:iterate>
    </xsl:function>

    <xsl:function name="tdl:count-flashers" as="xs:integer">
        <xsl:param name="board" as="array(array(xs:integer))"/>

        <xsl:sequence select="count(array:flatten($board)[. eq 0])"/>
    </xsl:function>

    <xsl:function name="tdl:neighbors" as="map(xs:string, xs:integer) +">
        <xsl:param name="point" as="map(xs:string, xs:integer)"/>

        <xsl:variable name="leftmost" as="xs:boolean" select="$point?x eq 1"/>
        <xsl:variable name="rightmost" as="xs:boolean" select="$point?x eq array:size($initial-board)"/>
        <xsl:variable name="on-bottom" as="xs:boolean" select="$point?y eq 1"/>
        <xsl:variable name="on-top" as="xs:boolean" select="$point?y eq array:size($initial-board(1))"/>

        <xsl:if test="not($leftmost)">
            <xsl:sequence select="map{ 'x': $point?x - 1, 'y': $point?y }"/>
        </xsl:if>
        <xsl:if test="not($rightmost)">
            <xsl:sequence select="map{ 'x': $point?x + 1, 'y': $point?y }"/>
        </xsl:if>
        <xsl:if test="not($on-bottom)">
            <xsl:sequence select="map{ 'x': $point?x, 'y': $point?y - 1 }"/>
        </xsl:if>
        <xsl:if test="not($on-top)">
            <xsl:sequence select="map{ 'x': $point?x, 'y': $point?y + 1 }"/>
        </xsl:if>
        <xsl:if test="not($on-bottom) and not($leftmost)">
            <xsl:sequence select="map{ 'x': $point?x - 1, 'y': $point?y - 1}"/>
        </xsl:if>
        <xsl:if test="not($on-bottom) and not($rightmost)">
            <xsl:sequence select="map{ 'x': $point?x + 1, 'y': $point?y - 1}"/>
        </xsl:if>
        <xsl:if test="not($on-top) and not($leftmost)">
            <xsl:sequence select="map{ 'x': $point?x - 1, 'y': $point?y + 1}"/>
        </xsl:if>
        <xsl:if test="not($on-top) and not($rightmost)">
            <xsl:sequence select="map{ 'x': $point?x + 1, 'y': $point?y + 1}"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="tdl:parse-board" as="array(array(xs:integer))">
        <xsl:param name="lines" as="xs:string +"/>

        <xsl:sequence select="
            array {
                for $x in (1 to string-length($lines[1]))
                return array { 
                    for $y in reverse(1 to count($lines))
                    return xs:integer(substring($lines[$y], $x, 1))
                 }
            }"/>
    </xsl:function>

</xsl:stylesheet>