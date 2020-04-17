<?xml version="1.0" encoding="UTF-8"?>
<!-- Basic MODS -->
<xsl:stylesheet version="1.0"
  xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"
     exclude-result-prefixes="mods java">
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <!--<xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/> -->
  <!--<xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/>-->
  <!-- HashSet to track single-valued fields. -->
  <xsl:variable name="single_valued_hashset" select="java:java.util.HashSet.new()"/>
  <xsl:variable name="digits" select="'1234567890'"/>

  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS">
    <xsl:param name="content"/>
    <xsl:param name="prefix"></xsl:param>
    <xsl:param name="suffix">ms</xsl:param>

    <!-- Clearing hash in case the template is ran more than once. -->
    <xsl:variable name="return_from_clear" select="java:clear($single_valued_hashset)"/>

    <xsl:apply-templates mode="utk_MODS" select="$content//mods:mods[1]"/>
    <xsl:apply-templates mode="utk_MODS_dates" select="$content//mods:mods[1]/mods:originInfo"/>
  </xsl:template>
  
  <!--
    additional templating for our MODS name/roles and geographic terms/coordinates
  -->
  <!-- the following template creates an _ms name+role field -->
  <xsl:template match="mods:mods/mods:name" mode="utk_MODS">
    <xsl:variable name="vName" select="child::mods:namePart[not(@type)]"/>
    <xsl:variable name="vRole">
      <xsl:if test="child::mods:role/mods:roleTerm">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="child::mods:role/mods:roleTerm">
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:if test="not(position()=last())">,</xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDate">
      <xsl:if test="child::mods:namePart[@type='date']">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:namePart[@type='date']"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDescription">
      <xsl:if test="child::mods:description">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:description"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_name_role_ms">
      <xsl:choose>
        <xsl:when test="$vRole=''">
          <xsl:value-of select="concat($vName,$vDate,$vDescription)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vName,$vDate,$vDescription,' ',$vRole)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_titleInfo_title_ms -->
  <xsl:template match="mods:mods/mods:titleInfo[not(@supplied)]/mods:title" mode="utk_MODS">
    <field name="utk_mods_titleInfo_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a Supplied Title field -->
  <xsl:template match="mods:mods/mods:titleInfo[@supplied='yes']/mods:title" mode="utk_MODS">
    <field name="utk_mods_supplied_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- the following template creates an archivalCollection+archivalIdentifier_ms field and facet field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='host'][@displayLabel='Collection']" mode="utk_MODS">
    <xsl:variable name="vColl" select="child::mods:titleInfo/mods:title"/>
    <xsl:variable name="vArchivalID">
      <xsl:if test="child::mods:identifier[@type='local']">
        <xsl:value-of select="child::mods:identifier"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_archColl_archID_ms">
      <xsl:choose>
        <xsl:when test="$vArchivalID=''">
          <xsl:value-of select="$vColl"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vColl,', ',$vArchivalID)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>

    <field name="utk_mods_relatedItem_titleInfo_title_ms">
      <xsl:value-of select="$vColl"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Related Work Field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='otherVersion']" mode="utk_MODS">
    <xsl:variable name="related_work" select="child::mods:titleInfo/mods:title"/>
    <field name="utk_mods_relate_work_ms">
      <xsl:value-of select="$related_work"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Extent Field -->
  <xsl:template match="mods:mods/mods:physicalDescription/mods:extent" mode="utk_MODS">
    <field name="utk_mods_physicalDescription_extent_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Form Field -->
  <xsl:template match="mods:mods/mods:physicalDescription/mods:form" mode="utk_MODS">
    <xsl:choose>
      <xsl:when test="self::node()[@authority]">
        <field name="utk_mods_physicalDescription_form_authority_ms">
          <xsl:value-of select="normalize-space(.)"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="utk_mods_physicalDescription_form_ms">
          <xsl:value-of select="normalize-space(.)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Record Source Field -->
  <xsl:template match="mods:mods/mods:recordInfo/mods:recordContentSource" mode="utk_MODS">
    <field name="utk_mods_recordInfo_recordContentSource_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Digital Collection Field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='host'][@displayLabel='Project']/mods:titleInfo/mods:title" mode="utk_MODS">
    <field name="utk_mods_relatedItem_host_Project_titleInfo_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Digital Collection URL Field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='host'][@displayLabel='Project']/mods:location/mods:url" mode="utk_MODS">
    <field name="utk_mods_relatedItem_host_Project_location_url_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- An ugly subject template to rule all others -->
  <xsl:template match="mods:mods/mods:subject" mode="utk_MODS">
    <xsl:choose>
      <xsl:when test="self::node()[@authority]">
        <xsl:variable name="vAuthority">
          <xsl:choose>
            <xsl:when test="self::node()/@authority='dots'">
              <xsl:value-of select="', (Database of the Smokies)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='lcsh'">
              <xsl:value-of select="', (Library of Congress Subject Headings)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='fast'">
              <xsl:value-of select="', (FAST)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='local'">
              <xsl:value-of select="', (Local Subject Heading)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='naf'">
              <xsl:value-of select="', (Library of Congress Name Authority File)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='tgm'">
              <xsl:value-of select="', (Library of Congress Thesaurus for Graphic Materials)'"/>
            </xsl:when>
            <xsl:when test="self::node()/@authority='agrovoc'">
              <xsl:value-of select="', (AGROVOC)'"/>
            </xsl:when>
          </xsl:choose>
         </xsl:variable>
    
        <xsl:choose>
          <xsl:when test="self::node()[mods:topic]">
            <field name="utk_mods_subject_topic_ms">
              <xsl:value-of select="normalize-space(concat(child::mods:topic, $vAuthority))"/>
            </field>
            <field name="utk_mods_subject_topic_facet_ms">
              <xsl:value-of select="normalize-space(child::mods:topic)"/>
            </field>
          </xsl:when>
          <xsl:when test="self::node()[mods:geographic]">
            <xsl:variable name="vGeo" select="child::mods:geographic"/>
            <xsl:variable name="vCoords" select="child::mods:cartographics/mods:coordinates"/>
            <field name="utk_mods_geo_ms">
              <xsl:choose>
                <xsl:when test="$vCoords!=''">
                  <xsl:value-of select="concat($vGeo,' ','(',$vCoords,')')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$vGeo"/>
                </xsl:otherwise>
              </xsl:choose>
            </field>
            <field name="utk_mods_geo_facet_ms">
              <xsl:value-of select="normalize-space(child::mods:geographic)"/>
            </field>
          </xsl:when>
          <xsl:when test="self::node()[mods:temporal]">
            <field name="utk_mods_subject_temporal_ms">
              <xsl:value-of select="normalize-space(child::mods:temporal)"/>
            </field>
            <field name="utk_mods_subject_temporal_facet_ms">
              <xsl:value-of select="normalize-space(child::mods:temporal)"/>
            </field>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="self::node()[@displayLabel='Volunteer Voices Curriculum Topics']">
        <field name="utk_mods_subject_topic_curriculumTopics_ms">
          <xsl:value-of select="normalize-space(concat(child::mods:topic,' ','(','Volunteer Voices',')'))"/>
        </field>
        <field name="utk_mods_subject_topic_curriculumTopics_facets_ms">
          <xsl:value-of select="normalize-space(child::mods:topic)"/>
        </field>
      </xsl:when>
      <xsl:when test="self::node()[@displayLabel='Broad Topics']">
        <field name="utk_mods_subject_topic_broadTopics_ms">
          <xsl:value-of select="normalize-space(concat(child::mods:topic,' ','(','Volunteer Voices',')'))"/>
        </field>
        <field name="utk_mods_subject_topic_broadTopics_facets_ms">
          <xsl:value-of select="normalize-space(child::mods:topic)"/>
        </field>
      </xsl:when>
      <xsl:when test="self::node()[@displayLabel='Tennessee Social Studies K-12 Eras in American History']">
        <field name="utk_mods_subject_topic_socStudiesK12_ms">
          <xsl:value-of select="normalize-space(concat(child::mods:topic,' ','(','Volunteer Voices',')'))"/>
        </field>
        <field name="utk_mods_subject_topic_socStudiesK12_facets_ms">
          <xsl:value-of select="normalize-space(child::mods:topic)"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="self::node()[mods:topic]">
            <field name="utk_mods_subject_topic_ms">
              <xsl:value-of select="normalize-space(child::mods:topic)"/>
            </field>
            <field name="utk_mods_subject_topic_facets_ms">
              <xsl:value-of select="normalize-space(child::mods:topic)"/>
            </field>
          </xsl:when>
          <xsl:when test="self::node()[mods:temporal]">
            <field name="utk_mods_subject_temporal_ms">
              <xsl:value-of select="normalize-space(child::mods:temporal)"/>
            </field>
            <field name="utk_mods_subject_temporal_facets_ms">
              <xsl:value-of select="normalize-space(child::mods:temporal)"/>
            </field>
          </xsl:when>
          <xsl:when test="self::node()[mods:geographic]">
            <xsl:variable name="vGeo" select="child::mods:geographic"/>
            <xsl:variable name="vCoords" select="child::mods:cartographics/mods:coordinates"/>
            <field name="utk_mods_geo_ms">
              <xsl:choose>
                <xsl:when test="$vCoords!=''">
                  <xsl:value-of select="concat($vGeo,' ','(',$vCoords,')')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$vGeo"/>
                </xsl:otherwise>
              </xsl:choose>
            </field>
            <field name="utk_mods_geo_facet_ms">
              <xsl:value-of select="normalize-space(child::mods:geographic)"/>
            </field>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the following template creates an _ms field for abstract(s) -->
  <!-- pulls all all mods:abstracts into one _ms field. maybe overly greedy? -->
  <xsl:template match="mods:mods/mods:abstract" mode="utk_MODS">
    <field name="utk_mods_abstract_ms">
      <xsl:for-each select=".">
        <xsl:value-of select="concat(.,' ')"/>
      </xsl:for-each>
    </field>
  </xsl:template>
  
  <!-- Build instrumentation facet. -->
  <xsl:template match="mods:mods/mods:note[@type='instrumentation']" mode="utk_MODS">
    <field name="utk_mods_note_instrumentation_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add a tableOfContents field -->
  <xsl:template match="mods:mods/mods:tableOfContents" mode="utk_MODS">
    <field name="utk_mods_toc_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_typeOfResource_ms for typeOfResource values-->
  <xsl:template match="mods:mods/mods:typeOfResource" mode="utk_MODS">
    <field name="utk_mods_typeOfResource_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_accessCondition_local_ms for values not associated with the type attributes of "use and reproduction" or "restriction on access"-->
  <xsl:template match="mods:mods/mods:accessCondition" mode="utk_MODS">
    <field name="utk_mods_accessCondition_local_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_accessCondition_use_and_reproduction_ms for Standardized Rights values-->
  <xsl:template match="mods:mods/mods:accessCondition[@type='use and reproduction']" mode="utk_MODS">
    <field name="utk_mods_accessCondition_use_and_reproduction_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_accessCondition_restrictions_on_access_ms for Restricted values -->
  <xsl:template match="mods:mods/mods:accessCondition[@type='restriction on access']" mode="utk_MODS">
    <field name="utk_mods_accessCondition_restrictions_on_access_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_genre_ms for genre values-->
  <xsl:template match="mods:mods/mods:genre" mode="utk_MODS">
    <field name="utk_mods_genre_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_identifier_ms for local identifier values-->
  <xsl:template match="mods:mods/mods:identifier" mode="utk_MODS">
    <xsl:if test="self::node()[@type='local'] or self::node()[@type='filename']">
      <field name="utk_mods_identifier_ms">
        <xsl:value-of select="normalize-space(.)"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- add utk_mods_identifier_misc_ms for miscellaneous identifier values-->
  <xsl:template match="mods:mods/mods:identifier" mode="utk_MODS">
    <xsl:if test="self::node()[not(@type='local')] or self::node()[not(@type='filename')] or self::node()[not(@type='issn')] or self::node()[not(@type='isbn')] or self::node()[not(@type='pid')]">
      <field name="utk_mods_identifier_misc_ms">
        <xsl:value-of select="normalize-space(.)"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- add utk_mods_publication_identifier_ms for ISSN or ISBN identifier values-->
  <xsl:template match="mods:mods/mods:identifier" mode="utk_MODS">
    <xsl:if test="self::node()[@type='issn'] or self::node()[@type='isbn']">
      <field name="utk_mods_publication_identifier_ms">
        <xsl:value-of select="normalize-space(.)"/>
      </field>
    </xsl:if>
  </xsl:template>
   
  <!-- add utk_mods_language_languageTerm_text_ms for language text -->
  <xsl:template match="mods:mods/mods:language/mods:languageTerm[@type='text']" mode="utk_MODS">
    <field name="utk_mods_language_languageTerm_text_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_location_physicalLocation_ms for physical locations -->
  <xsl:template match="mods:mods/mods:location/mods:physicalLocation" mode="utk_MODS">
    <field name="utk_mods_location_physicalLocation_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_note_ms for general notes and utk_mods_note_Transcribed_from_Original_Collection_ms for Transcriptions -->
  <xsl:template match="mods:mods/mods:note" mode="utk_MODS">
    <xsl:choose>
      <xsl:when test="self::node()[@displayLabel='Transcribed from Original Collection']">
        <field name="utk_mods_note_Transcribed_from_Original_Collection_ms">
          <xsl:value-of select="normalize-space(.)"/>
        </field>
      </xsl:when>
      <xsl:when test="self::node()[@displayLabel='dpn']"/>
      <xsl:otherwise>
        <field name="utk_mods_note_ms">
          <xsl:value-of select="normalize-space(.)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- add utk_mods_originInfo_place_placeTerm_ms for place terms -->
  <xsl:template match="mods:mods/mods:originInfo/mods:place/mods:placeTerm" mode="utk_MODS">
    <field name="utk_mods_originInfo_place_placeTerm_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_originInfo_publisher_ms for publishers -->
  <xsl:template match="mods:mods/mods:originInfo/mods:publisher" mode="utk_MODS">
    <field name="utk_mods_originInfo_publisher_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add mods_note_Tags_ms -->
  <xsl:template match="mods:mods/mods:note[@displayLabel='Tags']" mode="utk_MODS">
    <field name="utk_mods_note_Tags_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add utk_mods_relatedItem_featuredItem_titleInfo_title_ms -->
  <xsl:template match="mods:relatedItem[@displayLabel='Featured Item']/mods:titleInfo/mods:title" mode="utk_MODS">
    <field name="utk_mods_relatedItem_featuredItem_titleInfo_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_relatedItem_featuredItem_identifier_ms -->
  <xsl:template match="mods:relatedItem[@displayLabel='Featured Item']/mods:identifier" mode="utk_MODS">
    <field name="utk_mods_relatedItem_featuredItem_identifier_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_relatedItem_featuredItem_abstract_ms -->
  <xsl:template match="mods:relatedItem[@displayLabel='Featured Item']/mods:abstract" mode="utk_MODS">
    <field name="utk_mods_relatedItem_featuredItem_abstract_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add utk_mods_relatedItem_featuredItem_date_ms -->
  <xsl:template match="mods:relatedItem[@displayLabel='Featured Item']/mods:originInfo[mods:dateCreated or mods:dateIssued]" mode="utk_MODS">
    <field name="utk_mods_relatedItem_featuredItem_date_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- refactor _ms date fields back in to the utk_MODS mode -->
  <!-- add _dateIssued_ms -->
  <xsl:template match="mods:mods/mods:originInfo/mods:dateIssued[not(@encoding)]" mode="utk_MODS">
    <field name="utk_mods_originInfo_dateIssued_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>
  
  <!-- add _originInfo_date_ms -->
  <xsl:template match="mods:mods/mods:originInfo[mods:dateCreated[not(@encoding)] or mods:dateOther[not(@encoding)]]" mode="utk_MODS">
    <field name="utk_mods_originInfo_date_ms">
      <xsl:value-of select="child::mods:*[contains(local-name(),'dateCreated') or contains(local-name(),'dateOther')][not(@encoding)]"/>
    </field>
  </xsl:template>
  
  <!-- add _decade_ms -->
  <xsl:template match="mods:mods/mods:originInfo/mods:dateCreated[@encoding='edtf']" mode="utk_MODS">
    <xsl:variable name="decade" select="substring(normalize-space(.), 1, 3)"/>
    <field name="utk_mods_dateCreated_decade_ms">
      <xsl:value-of select="concat($decade, '0s')"/>
    </field>
  </xsl:template>
  
  <!-- try to refactor all of the mods:mods/mods:originInfo/mods:date* _dt handling to one template -->
  <xsl:template match="mods:mods/mods:originInfo" mode="utk_MODS_dates">
    <xsl:param name="pid"/>
    <xsl:param name="datastream"/>
    
    <!-- call templates for mods:dateCreatd[@encoding='edtf'][@point] -->
    <xsl:if test="child::mods:dateCreated[@encoding='edtf'][@point='start']">
      <xsl:call-template name="edtf_point_start">
        <xsl:with-param name="pid"/>
        <xsl:with-param name="datastream"/>
      </xsl:call-template>  
    </xsl:if>
    <xsl:if test="child::mods:dateCreated[@encoding='edtf'][@point='end']">
      <xsl:call-template name="edtf_point_end">
        <xsl:with-param name="pid"/>
        <xsl:with-param name="datastream"/>
      </xsl:call-template> 
    </xsl:if>
    
    <!-- call templates for mods:dateCreated[@encoding='edtf'] -->
    <xsl:if test="child::mods:dateCreated[@encoding='edtf']">
      <xsl:call-template name="edtf">
        <xsl:with-param name="pid"/>
        <xsl:with-param name="datastream"/>
      </xsl:call-template>
      
    </xsl:if>
    
    <!-- call templates for mods:dateIssued[@encoding='edtf'] -->
    <xsl:if test="child::mods:dateIssued[@encoding='edtf']">
      <xsl:call-template name="date_issued_edtf">
        <xsl:with-param name="pid"/>
        <xsl:with-param name="datastream"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- call templates for mods:dateOther[@encoding='edtf'] -->
    <xsl:if test="child::mods:dateOther[@encoding='edtf']">
      <xsl:call-template name="date_other_edtf">
        <xsl:with-param name="pid"/>
        <xsl:with-param name="datastream"/>
      </xsl:call-template>
    </xsl:if>
    
  </xsl:template>
  
  <!-- process mods:dateCreated[@encoding='edtf'][@point='start'] -->
  <xsl:template name="edtf_point_start">
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <xsl:variable name="point_start">
      <xsl:call-template name="get_ISO8601_edtf_date">
        <xsl:with-param name="date" select="normalize-space(child::mods:dateCreated[@encoding='edtf'][@point='start'])"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="not(normalize-space($point_start)='')">
        <field name="utk_mods_originInfo_dateCreated_edtf_point_start_dt">
          <xsl:value-of select="normalize-space($point_start)"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="utk_mods_date_feedback_ms">
          <xsl:value-of select="concat('edtf_point_start: ', $point_start)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- process mods:dateCreated[@encoding='edtf'][@point='end'] -->
  <xsl:template name="edtf_point_end">
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <xsl:variable name="point_end">
      <xsl:call-template name="get_ISO8601_date">
        <xsl:with-param name="date" select="child::mods:dateCreated[@encoding='edtf'][@point='end']"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="not(normalize-space($point_end)='')">
        <field name="utk_mods_originInfo_dateCreated_edtf_point_end_dt">
          <xsl:value-of select="normalize-space($point_end)"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="utk_mods_date_feedback_ms">
          <xsl:value-of select="concat('edtf_point_end', $point_end)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>  
  </xsl:template>
  
  <!-- process mods:dateCreated[@encoding='edtf'] -->
  <xsl:template name="edtf">
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>

    <xsl:variable name="normalized-date" select="normalize-space(child::mods:dateCreated[@encoding='edtf'])"/>
    
    <xsl:choose>
      <!--
        catches '[...]'; e.g. kefauver:150412001 and kefauver:150412002
      -->
      <xsl:when test="contains($normalized-date, '[')">
        <xsl:variable name="date-range-start">
          <xsl:call-template name="get_ISO8601_edtf_date">
            <xsl:with-param name="date" select="substring-after(substring-before($normalized-date, '-'), '[')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="date-range-end">
          <xsl:call-template name="get_ISO8601_edtf_date">
            <xsl:with-param name="date" select="substring-after(substring-before($normalized-date, ']'), '-')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>            
          </xsl:call-template>
        </xsl:variable>
        
        <!-- sub-choose b/c -->
        <xsl:choose>
          <!-- 
            this sub-choose creates _edtf_range_start and edtf_range_end _dt fields,
            otherwise creating a _feedback_ms field.
          -->
          <xsl:when test="not(normalize-space($date-range-start)='') and not(normalize-space($date-range-end)='')">
            <field name="utk_mods_originInfo_dateCreated_edtf_range_start_dt">
              <xsl:value-of select="normalize-space($date-range-start)"/>
            </field>
            <field name="utk_mods_originInfo_dateCreated_edtf_range_end_dt">
              <xsl:value-of select="normalize-space($date-range-end)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('edtf_date_range_1: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <!-- 
        second range pattern, this one for all the solidi ('/')
      -->
      <xsl:when test="contains($normalized-date, '/')">
        <xsl:variable name="date-range-start">
          <xsl:call-template name="get_ISO8601_date">
            <xsl:with-param name="date" select="substring-before($normalized-date, '/')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="date-range-end">
          <xsl:call-template name="get_ISO8601_date">
            <xsl:with-param name="date" select="substring-after($normalized-date, '/')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        
        <!-- sub-choose b/c -->
        <xsl:choose>
          <!-- 
            this sub-choose creates _edtf_range_start and edtf_range_end _dt fields,
            otherwise creating an _edtf_range_fallback_s field.
          -->
          <xsl:when test="not(normalize-space($date-range-start) = '') and not(normalize-space($date-range-end) = '')">
            <field name="utk_mods_originInfo_dateCreated_edtf_range_start_dt">
              <xsl:value-of select="normalize-space($date-range-start)"/>
            </field>
            <field name="utk_mods_originInfo_dateCreated_edtf_range_end_dt">
              <xsl:value-of select="normalize-space($date-range-end)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('edtf_date_range_2: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- 
        catch dates that look like '2018-05-22' or '2018' or '2018-05'...
        basically anything that doesn't have a [], or a /, or some other edtf
        signifier.
      -->
      <xsl:when test="not(contains($normalized-date, '~')) or not(contains($normalized-date, 'uU')) or not(contains($normalized-date, '?'))">
        <xsl:variable name="plain-edtf">
          <xsl:call-template name="get_ISO8601_edtf_date">
            <xsl:with-param name="date" select="$normalized-date"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        
        <!-- sub-choose b/c -->
        <xsl:choose>
          <xsl:when test="not(normalize-space($plain-edtf) = '')">
            <field name="utk_mods_originInfo_dateCreated_edtf_date_dt">
              <xsl:value-of select="normalize-space($plain-edtf)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('plain_edtf: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- unknown date patterns -->
      <xsl:when test="contains($normalized-date, '~') or contains($normalized-date, 'uU') or contains($normalized-date, '?')">
        <xsl:variable name="uncertainty-patterns">
          <xsl:call-template name="get_ISO8601_edtf_date">
            <xsl:with-param name="date" select="$normalized-date"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
      
        <!-- sub-choose, b/c -->
        <xsl:choose>
          <xsl:when test="not(normalize-space($uncertainty-patterns) = '')">
            <field name="utk_mods_originInfo_dateCreated_edtf_uncertain_date_dt">
              <xsl:value-of select="normalize-space($uncertainty-patterns)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('uncertainty_patterns: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    
      <!-- closing otherwise -->
      <xsl:otherwise>
        <field name="utk_mods_date_feedback_ms">
          <xsl:value-of select="concat('edtf_closing_otherwise: ', $normalized-date)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- process dateIssued[@encoding='edtf'] -->
  <xsl:template name="date_issued_edtf">
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <xsl:variable name="edtf-date">
      <xsl:call-template name="get_ISO8601_edtf_date">
        <xsl:with-param name="date" select="normalize-space(child::mods:dateIssued[@encoding='edtf'])"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="not(normalize-space($edtf-date)='')">
        <field name="utk_mods_originInfo_dateIssued_edtf_dt">
          <xsl:value-of select="normalize-space($edtf-date)"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="utk_mods_date_feedback_ms">
          <xsl:value-of select="concat('date_issued_edtf: ', $edtf-date)"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- process dateOther[@encoding='edtf'] -->
  <xsl:template name="date_other_edtf">
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <xsl:variable name="normalized-date" select="normalize-space(child::mods:dateOther[@encoding='edtf'])"/>
    
    <xsl:choose>
      <!-- 
        it appears that we only need to be concerned with '/' in our dateOthers
      -->
      <xsl:when test="contains($normalized-date, '/')">
        <xsl:variable name="date-range-start">
          <xsl:call-template name="get_ISO8601_date">
            <xsl:with-param name="date" select="substring-before($normalized-date, '/')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="date-range-end">
          <xsl:call-template name="get_ISO8601_date">
            <xsl:with-param name="date" select="substring-after($normalized-date, '/')"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
      
        <!-- sub-choose b/c -->
        <xsl:choose>
          <!--
            this sub-choose creates _edtf_range_start and _edtf_range_end fields,
            otherwise creating a _feedback_ms field.
          -->
          <xsl:when test="not(normalize-space($date-range-start)='') and not(normalize-space($date-range-end)='')">
            <field name="utk_mods_originInfo_dateOther_edtf_range_start_dt">
              <xsl:value-of select="normalize-space($date-range-start)"/>
            </field>
            <field name="utk_mods_originInfo_dateOther_edtf_range_end_dt">
              <xsl:value-of select="normalize-space($date-range-end)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('date_other_edtf: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:variable name="date-other-simple">
          <xsl:call-template name="get_ISO8601_edtf_date">
            <xsl:with-param name="date" select="$normalized-date"/>
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="datastream" select="$datastream"/>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
          <xsl:when test="not(normalize-space($date-other-simple)='')">
            <field name="utk_mods_originInfo_dateOther_edtf_dt">
              <xsl:value-of select="normalize-space($date-other-simple)"/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="utk_mods_date_feedback_ms">
              <xsl:value-of select="concat('date_other_simple: ', $normalized-date)"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="get_ISO8601_date">
    <xsl:param name="date"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <xsl:value-of select="java:ca.discoverygarden.gsearch_extensions.JodaAdapter.transformForSolr($date, $pid, $datastream)"/>
  </xsl:template>
  
  <xsl:template name="get_ISO8601_edtf_date">
    <xsl:param name="date"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    
    <!-- modifying the EDTF template for level 2 date shorthands -->
    <xsl:variable name="seasonal-dates">
      <xsl:choose>
        <xsl:when test="$date = ''"/>
        <!-- matches YYYY-21 (= spring or `-03-21`) -->
        <xsl:when test="string-length(translate(substring($date, 1, 4), $digits, '')) = 0
                        and substring($date, 5, 1) = '-'
                        and substring($date, 6, 2) = 21">
          <xsl:value-of select="concat(substring($date, 1, 4), '-03-21')"/>
        </xsl:when>
        <!-- matches YYYY-22 (= summer or `-06-21`) -->
        <xsl:when test="string-length(translate(substring($date, 1, 4), $digits, '')) = 0
                        and substring($date, 5, 1) = '-'
                        and substring($date, 6, 2) = 22">
          <xsl:value-of select="concat(substring($date, 1, 4), '-06-21')"/>
        </xsl:when>
        <!-- matches YYYY-23 (= autumn or `-09-21`) -->
        <xsl:when test="string-length(translate(substring($date, 1, 4), $digits, '')) = 0
                        and substring($date, 5, 1) = '-'
                        and substring($date, 6, 2) = 23">
          <xsl:value-of select="concat(substring($date, 1, 4), '-09-21')"/>
        </xsl:when>
        <!-- matches YYYY-24 (= winter or `-12-21`) -->
        <xsl:when test="string-length(translate(substring($date, 1, 4), $digits, '')) = 0
                        and substring($date, 5, 1) = '-'
                        and substring($date, 6, 2) = 24">
          <xsl:value-of select="concat(substring($date, 1, 4), '-12-21')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$date"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- EDTF stores unknown numbers as 'u' or 'U'; normalizing to 0. -->
    <!-- Only regard the portion of the date before a '/', as this indicates a
         range we wish to round down. -->
    <xsl:variable name="translated_date">
      <xsl:choose>
        <xsl:when test="contains($date, '/')">
          <xsl:value-of select="translate(substring-before($date, '/'), 'uU', '00')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate($date, 'uU', '00')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- Round down approximations as well; these either end in '?' or '~'. -->
    <xsl:variable name="date_prefix">
      <xsl:choose>
        <xsl:when test="contains($translated_date, '?')">
          <xsl:value-of select="substring-before($translated_date, '?')"/>
        </xsl:when>
        <xsl:when test="contains($translated_date, '~')">
          <xsl:value-of select="substring-before($translated_date, '~')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$translated_date"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:value-of select="java:ca.discoverygarden.gsearch_extensions.JodaAdapter.transformForSolr($seasonal-dates, $pid, $datastream)"/>
    
  </xsl:template>
  
</xsl:stylesheet>