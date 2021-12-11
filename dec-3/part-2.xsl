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

    <xsl:variable name="ratings" as="xs:string +" select="unparsed-text-lines('input.txt')"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="ratings-arr" as="array(*)" select="
            array {
                $ratings ! array { tdl:split-string(.) ! xs:integer(.)}
            }
        "/>

        <xsl:variable name="oxygen-rating" as="xs:integer +" select="tdl:find-rating($ratings-arr, true())"/>

        <xsl:variable name="scrubber-rating" as="xs:integer +" select="tdl:find-rating($ratings-arr, false())"/>

        <xsl:text>Oxygen generator rating: {$oxygen-rating}
CO2 scrubber rating:     {$scrubber-rating}
Life support rating:     {tdl:binary-to-decimal($oxygen-rating) * tdl:binary-to-decimal($scrubber-rating)}</xsl:text>
    </xsl:template>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($str) ! codepoints-to-string(.)"/>
    </xsl:function>

    <xsl:function name="tdl:find-rating" as="xs:integer +">
        <xsl:param name="ratings" as="array(*)"/>
        <xsl:param name="use-most-common" as="xs:boolean"/>

        <xsl:sequence select="tdl:_find-rating($ratings, $use-most-common, 1) => array:flatten()"/>
    </xsl:function>

    <xsl:function name="tdl:_find-rating" as="array(*)">
        <xsl:param name="ratings" as="array(*)"/>
        <xsl:param name="use-most-common" as="xs:boolean"/>
        <xsl:param name="pos" as="xs:integer"/>

        <xsl:choose>
            <xsl:when test="array:size($ratings) eq 0">
                <xsl:message select="'Accidentally eliminated all ratings from consideration, something went wrong'" terminate="true"/>
            </xsl:when>
            <xsl:when test="array:size($ratings) eq 1">
                <xsl:sequence select="$ratings(1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="most-common" as="xs:integer"
                    select="tdl:most-common($ratings, $pos)"/>
                <xsl:variable name="accept-value" as="xs:integer"
                    select="if ($use-most-common) then $most-common else tdl:bitwise-inverse($most-common)"/>

                <xsl:variable name="remaining-ratings" as="array(*)" select="
                    array {
                        for $i in (1 to array:size($ratings))
                            return  if ($ratings($i)($pos) eq $accept-value)
                                    then ($ratings($i))
                                    else ()
                    }
                "/>

                <xsl:sequence select="tdl:_find-rating($remaining-ratings, $use-most-common, $pos + 1)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="tdl:most-common" as="xs:integer">
        <xsl:param name="ratings" as="array(*)"/>
        <xsl:param name="pos" as="xs:integer"/>

        <xsl:sequence select="
            let $size    := array:size($ratings),
                $members := (for $i in (1 to $size)
                                return $ratings($i)($pos)),
                $sum     := sum($members)
                return if ($sum ge ($size idiv 2)) then 1 else 0
        "/>
    </xsl:function>

    <xsl:function name="tdl:binary-to-decimal" as="xs:integer">
        <xsl:param name="bits" as="xs:integer +"/>

        <xsl:sequence select="tdl:_binary-to-decimal(reverse($bits), 1, 0)"/>
    </xsl:function>

    <xsl:function name="tdl:_binary-to-decimal" as="xs:integer +">
        <xsl:param name="bits" as="xs:integer +"/>
        <xsl:param name="pos" as="xs:integer"/>
        <xsl:param name="sum" as="xs:integer"/>

        <xsl:choose>
            <xsl:when test="$pos gt count($bits)">
                <xsl:sequence select="$sum"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="value" as="xs:integer" select="xs:integer($bits[$pos] * math:pow(2, ($pos - 1)))"/>

                <xsl:sequence select="tdl:_binary-to-decimal($bits, $pos+1, $sum + $value)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tdl:bitwise-inverse" as="xs:integer +">
        <xsl:param name="bits" as="xs:integer +"/>

        <xsl:sequence select="$bits ! (if (. eq 1) then 0 else 1)"/>
    </xsl:function>

</xsl:stylesheet>