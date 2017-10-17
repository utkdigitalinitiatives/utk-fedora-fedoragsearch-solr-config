<?xml version="1.0" encoding="UTF-8"?>
<!-- Basic MODS -->
<xsl:stylesheet version="1.0"
  xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"
     exclude-result-prefixes="mods java">
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/> -->
  <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/>
  <!-- HashSet to track single-valued fields. -->
  <xsl:variable name="single_valued_hashset" select="java:java.util.HashSet.new()"/>

  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS">
    <xsl:param name="content"/>
    <xsl:param name="prefix"></xsl:param>
    <xsl:param name="suffix">ms</xsl:param>

    <!-- Clearing hash in case the template is ran more than once. -->
    <xsl:variable name="return_from_clear" select="java:clear($single_valued_hashset)"/>

    <xsl:apply-templates mode="slurping_MODS" select="$content//mods:mods[1]">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="../../@PID"/>
      <xsl:with-param name="datastream" select="../@ID"/>
    </xsl:apply-templates>


    <!--
      creates a mode for MODS record that *do* have a mods:identifier starting with 'utk_' (migration data!) *OR* a
      mods:genre = 'Academic theses'.
    -->
    <xsl:apply-templates mode="utk_ir_MODS" select="$content//mods:mods[1]"/>
	<xsl:apply-templates mode="utk_mods_etd" select="$content//mods:mods[1]"/>
  </xsl:template>

  <!-- utk_ir_MODS mode -->
  <!-- the following template creates an _ms field for author(s) -->
  <xsl:template match="mods:mods/mods:name[(mods:role/mods:roleTerm='Author') or (mods:role/mods:roleTerm='author')]" mode="utk_ir_MODS">
    <xsl:variable name="given-n" select="mods:namePart[@type='given']"/>
    <xsl:variable name="family-n" select="mods:namePart[@type='family']"/>
    <xsl:variable name="t-o-address" select="mods:namePart[@type='termsOfAddress']"/>

    <field name="utk_mods_ir_name_author_ms">
      <xsl:choose>
        <xsl:when test="$t-o-address!=''">
          <xsl:value-of select="concat($given-n, ' ', $family-n, ', ', $t-o-address)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($given-n, ' ', $family-n)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

  <!-- utk_mods_etd mode -->
  <!-- utk_mods_etd mode --> 


  <!-- JIRA TRAC-875 Define utk_mods_etd_author in Solr -->
  <!-- the following template creates an _s field for single etd author -->
  <!-- need to  use single_valued_hashset -->
  <xsl:template match="mods:mods/mods:name[(mods:role/mods:roleTerm='Author') or 
    (mods:role/mods:roleTerm='author')]" mode="utk_mods_etd">
    <xsl:variable name="given-n" select="mods:namePart[@type='given']"/>
    <xsl:variable name="family-n" select="mods:namePart[@type='family']"/>
    <xsl:variable name="t-o-address" select="mods:namePart[@type='termsOfAddress']"/>

     <field name="utk_etd_mods_name_author_s">
       <xsl:choose>
          <xsl:when test="$t-o-address!=''">
               <xsl:value-of select="concat($given-n, ' ', $family-n, ', ', $t-o-address)"/>
        </xsl:when>
        <xsl:otherwise>
              <xsl:value-of select="concat($given-n, ' ', $family-n)"/>
        </xsl:otherwise>
        </xsl:choose>
    </field>
  </xsl:template>


  <!-- utk_mods_etd  -->
  <!-- utk_mods_etd  -->

  
  <!-- JIRA TRAC-875 Define utk_mods_etd_author in Solr -->
  <!-- the following template creates an _s field for single etd author -->
  <xsl:template match="mods:mods/mods:name[(mods:role/mods:roleTerm='Author') or (mods:role/mods:roleTerm='author')]" mode="utk_ir_MODS">
    <xsl:variable name="given-n" select="mods:namePart[@type='given']"/>
    <xsl:variable name="family-n" select="mods:namePart[@type='family']"/>
    <xsl:variable name="t-o-address" select="mods:namePart[@type='termsOfAddress']"/>

    <field name="utk_mods_etd_author_s">
      <xsl:choose>
        <xsl:when test="$t-o-address!=''">
          <xsl:value-of select="concat($given-n, ' ', $family-n, ', ', $t-o-address)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($given-n, ' ', $family-n)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>



  <!-- the following template creates an _ms field for thesis advisors -->
  <xsl:template match="mods:mods/mods:name[(mods:role/mods:roleTerm='Thesis advisor') or (mods:role/mods:roleTerm='thesis advisor')]" mode="utk_ir_MODS">
    <xsl:variable name="advisor" select="mods:displayForm"/>

    <field name="utk_mods_etd_name_thesis_advisor_ms">
      <xsl:value-of select="$advisor"/>
    </field>
  </xsl:template>

  <!-- the following template creates an _ms field for committee members -->
  <xsl:template match="mods:mods/mods:name[(mods:role/mods:roleTerm='Committee member') or (mods:role/mods:roleTerm='Committee Member')]" mode="utk_ir_MODS">
    <xsl:variable name="comm-member" select="mods:displayForm"/>

    <field name="utk_mods_etd_name_committee_member_ms">
      <xsl:value-of select="$comm-member"/>
    </field>
  </xsl:template>

  <!-- the following template creates a utk_mods_etd abstract field for all abstracts, in case there are multiple -->
  <xsl:template match="mods:mods/mods:abstract" mode="utk_ir_MODS">
    <field name="utk_mods_etd_abstract_ms">
      <xsl:for-each select=".">
        <xsl:value-of select="concat(., ' ')"/>
      </xsl:for-each>
    </field>
  </xsl:template>

  <!-- Handle dates. -->
  <xsl:template match="mods:*[(@type='date') or (contains(translate(local-name(), 'D', 'd'), 'date'))][normalize-space(text())]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>

    <xsl:variable name="rawTextValue" select="normalize-space(text())"/>

    <xsl:variable name="textValue">
      <xsl:call-template name="get_ISO8601_date">
        <xsl:with-param name="date" select="$rawTextValue"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Use attributes in field name. -->
    <xsl:variable name="this_prefix">
      <xsl:value-of select="$prefix"/>
      <xsl:for-each select="@*">
        <xsl:sort select="concat(local-name(), namespace-uri(self::node()))"/>
        <xsl:value-of select="local-name()"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="translate(., ' ', '_')"/>
        <xsl:text>_</xsl:text>
      </xsl:for-each>
    </xsl:variable>

    <!-- Prevent multiple generating multiple instances of single-valued fields
         by tracking things in a HashSet -->
    <xsl:variable name="field_name" select="normalize-space(concat($this_prefix, local-name()))"/>
    <!-- The method java.util.HashSet.add will return false when the value is
         already in the set. -->
    <xsl:if test="java:add($single_valued_hashset, $field_name)">
      <xsl:if test="not(normalize-space($textValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_dt')"/>
          </xsl:attribute>
          <xsl:value-of select="$textValue"/>
        </field>
      </xsl:if>
      <xsl:if test="not(normalize-space($rawTextValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_s')"/>
          </xsl:attribute>
          <xsl:value-of select="$rawTextValue"/>
        </field>
      </xsl:if>
    </xsl:if>

    <xsl:if test="not(normalize-space($textValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_mdt')"/>
        </xsl:attribute>
        <xsl:value-of select="$textValue"/>
      </field>
    </xsl:if>
    <xsl:if test="not(normalize-space($rawTextValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_ms')"/>
        </xsl:attribute>
        <xsl:value-of select="$rawTextValue"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!-- Avoid using text alone. -->
  <xsl:template match="text()" mode="slurping_MODS"/>

  <!-- Build up the list prefix with the element context. -->
  <xsl:template match="*" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="this_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(translate(@type, ' ', '_'), '_')"/>
      </xsl:if>
      <xsl:if test="@displayLabel">
        <xsl:value-of select="concat(translate(@displayLabel,' ','_'),'_')"/>
      </xsl:if>
    </xsl:variable>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$this_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!--
    The "eventType" attribute was introduce with MODS 3.5... Let's start
    exposing it for use.
  -->
  <xsl:template match="mods:originInfo" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_eventType_fork">
      <xsl:with-param name="prefix" select="concat($prefix, local-name(), '_')"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Intercept names with role terms, so we can create copies of the fields
    including the role term in the name of generated fields. (Hurray, additional
    specificity!) -->
  <xsl:template match="mods:name[mods:role/mods:roleTerm]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="base_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(translate(@type, ' ', '_'), '_')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:for-each select="mods:role/mods:roleTerm">
      <xsl:variable name="this_prefix" select="concat($base_prefix, translate(normalize-space(.), $uppercase, $lowercase), '_')"/>

      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="$this_prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="normalize-space(text())"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="../.."/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$base_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Fields are duplicated for authority because searches across authorities are common. -->
  <xsl:template name="mods_authority_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="general_mods_field">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@authority">
      <xsl:call-template name="general_mods_field">
        <xsl:with-param name="prefix" select="concat($prefix, 'authority_', translate(@authority, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Fork on eventType to preserve legacy field names. -->
  <xsl:template name="mods_eventType_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <xsl:if test="@eventType">
      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="concat($prefix, 'eventType_', translate(@eventType, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Want to include language in field names. -->
  <xsl:template name="mods_language_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_authority_fork">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@lang">
      <xsl:call-template name="mods_authority_fork">
        <xsl:with-param name="prefix" select="concat($prefix, 'lang_', translate(@lang, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Handle the actual indexing of the majority of MODS elements, including
    the recursive step of kicking off the indexing of subelements. -->
  <xsl:template name="general_mods_field">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid"/>
    <xsl:param name="datastream"/>
    <xsl:param name="node" select="current()"/>

    <xsl:if test="$value">
      <field>
        <xsl:attribute name="name">
          <xsl:choose>
            <!-- Try to create a single-valued version of each field (if one
              does not already exist, that is). -->
            <!-- XXX: We make some assumptions about the schema here...
              Primarily, _s getting copied to the same places as _ms. -->
            <xsl:when test="$suffix='ms' and java:add($single_valued_hashset, string($prefix))">
              <xsl:value-of select="concat($prefix, 's')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($prefix, $suffix)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="$value"/>
      </field>
    </xsl:if>
    <xsl:if test="normalize-space($node/@authorityURI)">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'authorityURI_', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$node/@authorityURI"/>
      </field>
    </xsl:if>

    <xsl:apply-templates select="$node/*" mode="slurping_MODS">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:apply-templates>
  </xsl:template>
</xsl:stylesheet>
