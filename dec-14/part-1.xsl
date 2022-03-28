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

    <xsl:variable name="template" as="xs:string" select="$input[1]"/>

    <xsl:variable name="rules" as="map(*)" select="map:merge($input[position() ge 3] ! tdl:parse-rule(.))"/>
    
    <xsl:template name="xsl:initial-template">
        <xsl:variable name="polymer" as="xs:string" select="tdl:polymerize($template, $rules, 10)"/>
        
        <xsl:variable name="frequencies" as="xs:integer +"
            select="(let $polymer-seq := tdl:split-string($polymer),
                        $materials   := distinct-values($polymer-seq)
                    return
                        for $material in $materials
                        return count($polymer-seq[. eq $material])
                    ) => sort()"/>

        <xsl:sequence select="$frequencies[last()] - $frequencies[1]"/>
    </xsl:template>

    <xsl:function name="tdl:polymerize" as="xs:string">
        <xsl:param name="template" as="xs:string"/>
        <xsl:param name="rules" as="map(*)"/>
        <xsl:param name="steps" as="xs:integer"/>

        <xsl:sequence select="fold-left((1 to $steps), $template,
            function($polymer, $_) {
                (for $i in (1 to (string-length($polymer) - 1))
                return
                    let $first  := substring($polymer, $i, 1),
                        $second := substring($polymer, $i + 1, 1),
                        $result := $rules($first || $second)
                    return  if      ($result)
                            then    ($first, $result)
                            else    ($first)
                , substring($polymer, string-length($polymer))
                ) => string-join()
            }
        )"/>
    </xsl:function>

    <xsl:function name="tdl:parse-rule" as="map(xs:string, xs:string)">
        <xsl:param name="rule" as="xs:string"/>
        
        <xsl:analyze-string select="$rule" regex="^([A-Z]{{2}}) -> ([A-Z])$">
            <xsl:matching-substring>
                <xsl:map-entry key="regex-group(1)" select="regex-group(2)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="tdl:split-string" as="xs:string *">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:sequence select="string-to-codepoints($string) ! codepoints-to-string(.)"/>
    </xsl:function>

</xsl:stylesheet>