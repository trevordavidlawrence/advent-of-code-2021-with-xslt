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

    <xsl:mode name="mark-number" on-no-match="shallow-copy"/>

    <xsl:variable name="input" as="xs:string +"
        select="unparsed-text-lines('input.txt')"/>

    <xsl:variable name="bingo-numbers" as="xs:integer +"
        select="tokenize($input[1], ',') ! xs:integer(.)"/>

    <xsl:variable name="initial-boards" as="document-node() +">
        <xsl:for-each-group select="$input[position() gt 1]"
            group-starting-with=".[matches(., '^\s*$')]">

            <xsl:document>
                <board>
                    <xsl:for-each select="current-group()[matches(., '\S')]">
                        <row>
                            <xsl:for-each select="tokenize(.)">
                                <col>{.}</col>
                            </xsl:for-each>
                        </row>
                    </xsl:for-each>
                </board>
            </xsl:document>
        </xsl:for-each-group>
    </xsl:variable>

    <xsl:template name="xsl:initial-template">
        <xsl:iterate select="$bingo-numbers">
            <xsl:param name="boards" select="$initial-boards"/>
            
            <xsl:variable name="number" select="."/>

            <xsl:variable name="modified-boards"
                select="$boards ! tdl:mark-number(., $number)"/>

            <xsl:variable name="winning-board"
                select="$modified-boards[tdl:has-win(.)][1]"/>

            <xsl:choose>
                <xsl:when test="exists($winning-board)">
                    <xsl:variable name="unmarked-number-sum" select="tdl:unmarked-number-sum($winning-board)"/>

                    <xsl:break>Unmarked number sum: {$unmarked-number-sum}
Winning number:      {$number}
Product:             {$unmarked-number-sum * $number}</xsl:break>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:next-iteration>
                        <xsl:with-param name="boards" select="$modified-boards"/>
                    </xsl:next-iteration>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:iterate>
    </xsl:template>

    <xsl:function name="tdl:mark-number" as="document-node()">
        <xsl:param name="board" as="document-node()"/>
        <xsl:param name="number" as="xs:integer"/>

        <xsl:apply-templates select="$board" mode="mark-number">
            <xsl:with-param name="number" as="xs:integer" tunnel="true"
                select="$number"/>
        </xsl:apply-templates>
    </xsl:function>

    <xsl:template match="col" mode="mark-number">
        <xsl:param name="number" as="xs:integer" tunnel="true"/>

        <xsl:copy>
            <xsl:if test="xs:integer(.) eq $number">
                <xsl:attribute name="marked" select="'true'"/>
            </xsl:if>

            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="tdl:has-win" as="xs:boolean">
        <xsl:param name="board" as="document-node()"/>

        <xsl:sequence
            select="exists($board/board/row[every $col in col satisfies $col/@marked])
                    or
                    exists((1 to 5)[let $pos := . return every $col in $board/board/row/col[$pos] satisfies $col/@marked])"/>
    </xsl:function>

    <xsl:function name="tdl:unmarked-number-sum" as="xs:integer">
        <xsl:param name="board" as="document-node()"/>
        
        <xsl:sequence select="($board/board/row/col[not(@marked)] ! xs:integer(.)) => sum()"/>
    </xsl:function>

    <xsl:function name="tdl:print-all-boards" as="xs:string +">
        <xsl:param name="boards" as="document-node() +"/>
        <xsl:param name="heading" as="xs:string"/>

        <xsl:sequence select="'====== ' || $heading || ' ======'"/>
        <xsl:sequence select="codepoints-to-string(10)"/>

        <xsl:for-each select="$boards">
            <xsl:sequence select="'=== Board #' || position() || ' ==='"/>
            <xsl:sequence select="codepoints-to-string(10)"/>
            <xsl:sequence select="tdl:print-board(.)"/>
            <xsl:sequence select="codepoints-to-string(10)"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="tdl:print-board" as="xs:string +">
        <xsl:param name="board" as="document-node()"/>
        
        <xsl:for-each select="$board/board/row">
            <xsl:for-each select="col">
                <xsl:variable name="number-formatted"
                    select="format-integer(xs:integer(.), '))')"/>

                <xsl:choose>
                    <xsl:when test="@marked">
                        <xsl:sequence select="'*' || $number-formatted || '*'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="' ' || $number-formatted || ' '"/>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:if test="position() ne last()">
                    <xsl:sequence select="' '"/>
                </xsl:if>
            </xsl:for-each>
            <xsl:sequence select="codepoints-to-string(10)"/>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>