<!--
    Table styling
-->

<!--
-->

<!DOCTYPE xsl:stylesheet [
<!ENTITY % common.entities SYSTEM "/opt/local/share/xsl/docbook-xsl/common/entities.ent">
%common.entities;
]>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format">

<xsl:attribute-set name="table.cell.padding">
  <xsl:attribute name="padding-start">3pt</xsl:attribute>
  <xsl:attribute name="padding-end">3pt</xsl:attribute>
  <xsl:attribute name="padding-top">3pt</xsl:attribute>
  <xsl:attribute name="padding-bottom">3pt</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="table.properties" use-attribute-sets="formal.object.properties">
  <xsl:attribute name="margin-left">-3pt</xsl:attribute>
  <xsl:attribute name="margin-right">-3pt</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="informaltable.properties" use-attribute-sets="informal.object.properties">
  <xsl:attribute name="margin-left">-3pt</xsl:attribute>
  <xsl:attribute name="margin-right">-3pt</xsl:attribute>
</xsl:attribute-set>

<xsl:template name="table.block">
  <xsl:param name="table.layout" select="NOTANODE"/>

  <xsl:variable name="id">
    <xsl:call-template name="object.id"/>
  </xsl:variable>

  <xsl:variable name="param.placement"
                select="substring-after(normalize-space(
                   $formal.title.placement), concat(local-name(.), ' '))"/>

  <xsl:variable name="placement">
    <xsl:choose>
      <xsl:when test="contains($param.placement, ' ')">
        <xsl:value-of select="substring-before($param.placement, ' ')"/>
      </xsl:when>
      <xsl:when test="$param.placement = ''">before</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$param.placement"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="keep.together">
    <xsl:call-template name="pi.dbfo_keep-together"/>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="self::table">
      <fo:block id="{$id}"
                xsl:use-attribute-sets="table.properties">
        <xsl:if test="$keep.together != ''">
          <xsl:attribute name="keep-together.within-column">
            <xsl:value-of select="$keep.together"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="$placement = 'before'">
          <xsl:call-template name="formal.object.heading">
            <xsl:with-param name="placement" select="$placement"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:copy-of select="$table.layout"/>
        <xsl:call-template name="table.footnote.block"/>
        <xsl:if test="$placement != 'before'">
          <xsl:call-template name="formal.object.heading">
            <xsl:with-param name="placement" select="$placement"/>
          </xsl:call-template>
        </xsl:if>
      </fo:block>
    </xsl:when>
    <xsl:otherwise>
      <fo:block id="{$id}"
                xsl:use-attribute-sets="informaltable.properties">
	<!--
	    NOTE 2012-05-14 hughg: Reduce space before/after tables in sidebars.
	-->
	<xsl:if test="ancestor::sidebar">
	  <xsl:attribute name="space-before.minimum">0em</xsl:attribute>
	  <xsl:attribute name="space-before.optimum">0em</xsl:attribute>
	  <xsl:attribute name="space-before.maximum">0em</xsl:attribute>
	  <xsl:attribute name="space-after.minimum">0em</xsl:attribute>
	  <xsl:attribute name="space-after.optimum">0em</xsl:attribute>
	  <xsl:attribute name="space-after.maximum">0em</xsl:attribute>
	</xsl:if>

        <xsl:if test="$keep.together != ''">
          <xsl:attribute name="keep-together.within-column">
            <xsl:value-of select="$keep.together"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:copy-of select="$table.layout"/>
        <xsl:call-template name="table.footnote.block"/>
      </fo:block>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<xsl:template name="table.cell.block.properties">
  <!-- highlight this entry? -->
  <xsl:choose>
    <xsl:when test="ancestor::thead or ancestor::tfoot">
      <xsl:attribute name="font-weight">bold</xsl:attribute>
      <xsl:attribute name="hyphenate">false</xsl:attribute>
    </xsl:when>
    <!-- Make row headers bold too -->
    <xsl:when test="ancestor::tbody and 
                    (ancestor::table[@rowheader = 'firstcol'] or
                    ancestor::informaltable[@rowheader = 'firstcol']) and
                    ancestor-or-self::entry[1][count(preceding-sibling::entry) = 0]">
      <xsl:attribute name="font-weight">bold</xsl:attribute>
      <xsl:attribute name="hyphenate">false</xsl:attribute>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<!-- Returns the table role for the context element -->
<xsl:template name="tabrole">
  <xsl:param name="node" select="."/>

  <xsl:variable name="tgroup" select="$node/tgroup[1] | 
                                      $node/ancestor-or-self::tgroup[1]"/>

  <xsl:variable name="table" 
                select="($node/ancestor-or-self::table | 
                         $node/ancestor-or-self::informaltable)[last()]"/>

  <xsl:variable name="tabrole">
    <xsl:choose>
      <xsl:when test="$table/@role != ''">
        <xsl:value-of select="normalize-space($table/@role)"/>
      </xsl:when>
      <xsl:when test="$tgroup/@role != ''">
        <xsl:value-of select="normalize-space($tgroup/@role)"/>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:value-of select="$tabrole"/>
</xsl:template>

<xsl:template name="table.row.properties">

  <xsl:variable name="tabrole">
    <xsl:call-template name="tabrole"/>
  </xsl:variable>

  <xsl:variable name="row-height">
    <xsl:if test="processing-instruction('dbfo')">
      <xsl:call-template name="pi.dbfo_row-height"/>
    </xsl:if>
  </xsl:variable>

  <xsl:if test="$row-height != ''">
    <xsl:attribute name="block-progression-dimension">
      <xsl:value-of select="$row-height"/>
    </xsl:attribute>
  </xsl:if>

  <xsl:variable name="bgcolor">
    <xsl:call-template name="pi.dbfo_bgcolor"/>
  </xsl:variable>

  <xsl:variable
      name="header_count"
      select="count(ancestor::table/thead) +
	      count(ancestor::informaltable/thead)"/>

  <xsl:variable name="rownum">
    <xsl:number from="tgroup" count="row"/>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$bgcolor != ''">
      <xsl:attribute name="background-color">
        <xsl:value-of select="$bgcolor"/>
      </xsl:attribute>
    </xsl:when>
<!--
    NOTE 2012-05-14 hughg: Make tables striped, unless they're in sidebars.
-->
    <xsl:when test="not(ancestor::sidebar)">
      <xsl:if test="($rownum - $header_count) mod 2 = 0">
        <xsl:attribute name="background-color">#D2D2D2</xsl:attribute>
      </xsl:if>
    </xsl:when>
  </xsl:choose>

  <!-- Keep header row with next row -->
  <xsl:if test="ancestor::thead">
    <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
  </xsl:if>

</xsl:template>

<xsl:template name="table.cell.properties">
  <xsl:param name="bgcolor.pi" select="''"/>
  <xsl:param name="rowsep.inherit" select="1"/>
  <xsl:param name="colsep.inherit" select="1"/>
  <xsl:param name="col" select="1"/>
  <xsl:param name="valign.inherit" select="''"/>
  <xsl:param name="align.inherit" select="''"/>
  <xsl:param name="char.inherit" select="''"/>

  <xsl:choose>
    <xsl:when test="ancestor::tgroup">
      <xsl:if test="$bgcolor.pi != ''">
        <xsl:attribute name="background-color">
          <xsl:value-of select="$bgcolor.pi"/>
        </xsl:attribute>
      </xsl:if>

      <!-- NOTE 2014-01-19 hughg: Reduce padding for cells inside sidebars. -->
      <xsl:if test="ancestor::sidebar">
<!--
	<xsl:attribute name="padding-start">0pt</xsl:attribute>
	<xsl:attribute name="padding-end">0pt</xsl:attribute>
-->
	<xsl:attribute name="padding-top">0pt</xsl:attribute>
	<xsl:attribute name="padding-bottom">0pt</xsl:attribute>
      </xsl:if>

      <xsl:if test="$rowsep.inherit &gt; 0">
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'bottom'"/>
        </xsl:call-template>
      </xsl:if>

      <xsl:if test="$colsep.inherit &gt; 0 and 
                      $col &lt; (ancestor::tgroup/@cols|ancestor::entrytbl/@cols)[last()]">
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'end'"/>
        </xsl:call-template>
      </xsl:if>

      <xsl:if test="$valign.inherit != ''">
        <xsl:attribute name="display-align">
          <xsl:choose>
            <xsl:when test="$valign.inherit='top'">before</xsl:when>
            <xsl:when test="$valign.inherit='middle'">center</xsl:when>
            <xsl:when test="$valign.inherit='bottom'">after</xsl:when>
            <xsl:otherwise>
              <xsl:message>
                <xsl:text>Unexpected valign value: </xsl:text>
                <xsl:value-of select="$valign.inherit"/>
                <xsl:text>, center used.</xsl:text>
              </xsl:message>
              <xsl:text>center</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>

      <xsl:choose>
        <xsl:when test="$align.inherit = 'char' and $char.inherit != ''">
          <xsl:attribute name="text-align">
            <xsl:value-of select="$char.inherit"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$align.inherit != ''">
          <xsl:attribute name="text-align">
            <xsl:value-of select="$align.inherit"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>

    </xsl:when>
    <xsl:otherwise>
      <!-- HTML table -->
      <xsl:if test="$bgcolor.pi != ''">
        <xsl:attribute name="background-color">
          <xsl:value-of select="$bgcolor.pi"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="$align.inherit != ''">
        <xsl:attribute name="text-align">
          <xsl:value-of select="$align.inherit"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="$valign.inherit != ''">
        <xsl:attribute name="display-align">
          <xsl:choose>
            <xsl:when test="$valign.inherit='top'">before</xsl:when>
            <xsl:when test="$valign.inherit='middle'">center</xsl:when>
            <xsl:when test="$valign.inherit='bottom'">after</xsl:when>
            <xsl:otherwise>
              <xsl:message>
                <xsl:text>Unexpected valign value: </xsl:text>
                <xsl:value-of select="$valign.inherit"/>
                <xsl:text>, center used.</xsl:text>
              </xsl:message>
              <xsl:text>center</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>

      <xsl:call-template name="html.table.cell.rules"/>

    </xsl:otherwise>
  </xsl:choose>

</xsl:template>



</xsl:stylesheet>
