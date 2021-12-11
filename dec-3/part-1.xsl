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

    <xsl:variable name="readings" as="xs:string +" select="unparsed-text-lines('input.txt')"/>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="readings-arr" as="array(*)" select="
            array {
                $readings ! (array { tdl:split-string(.) ! xs:integer(.) })
            }
        "/>

        <xsl:variable name="gamma-rate" as="xs:integer +" select="
            for $i in (1 to array:size($readings-arr(1)))
                return tdl:most-common($readings-arr, $i)
        "/>

        <xsl:variable name="epsilon-rate" as="xs:integer +" select="tdl:bitwise-inverse($gamma-rate)"/>

        <xsl:text>Gamma rate:   {$gamma-rate}
Epsilon rate: {$epsilon-rate}
Product:      {tdl:binary-to-decimal($gamma-rate) * tdl:binary-to-decimal($epsilon-rate)}</xsl:text>
    </xsl:template>   

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($str) ! codepoints-to-string(.)"/>
    </xsl:function> 

    <xsl:function name="tdl:most-common" as="xs:integer">
        <xsl:param name="arr" as="array(*)"/>
        <xsl:param name="pos" as="xs:integer"/>

        <xsl:sequence select="
            let $size    := array:size($arr),
                $members := (for $i in (1 to $size)
                                return $arr($i)($pos)),
                $sum     := sum($members)
                return if ($sum gt ($size idiv 2)) then 1 else 0
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