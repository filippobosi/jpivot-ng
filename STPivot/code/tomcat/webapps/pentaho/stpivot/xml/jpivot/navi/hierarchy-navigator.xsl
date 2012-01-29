<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<xsl:param name="imgpath2" select="'stpivot/style/jpivot/navi'"/>
	
	<xsl:template match="cat-edit">
		<div width="100%" style="float:right;">
			<img src="{$context}/{$imgpath2}/button_ok.png" alt="{@ok-title}" title="{@ok-title}" onclick="drillNavigator('{$token}&amp;{@ok-id}={@ok-title}',false,true)" style="cursor:pointer"/>
			<xsl:text> </xsl:text>
			<img src="{$context}/{$imgpath2}/button_cancel.png" alt="{@ok-cancel}" title="{@cancel-title}" onclick="drillNavigator('{$token}&amp;{@cancel-id}={@cancel-title}',true,false)" style="cursor:pointer"/>
		</div>
		<table cellpadding="1" cellspacing="0" border="0" id="{$renderId}" width="100%">
			<xsl:apply-templates select="cat-category"/>
		</table>
	</xsl:template>

	<xsl:template match="cat-category">
		<tr>
			<th align="left" class="navi-axis" colspan="3">
				<img src="{$context}/{$imgpath2}/{@icon}" width="9" height="9" alt="{@name}" title="{@name}"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="@name"/>
				<!--xsl:choose>
					<xsl:when test="position() = 1">
						<table border="0" cellspacing="0" cellpadding="0" width="100%">
							<tr>
								<th align="left" class="navi-axis">
									<img src="{$context}/{$imgpath2}/{@icon}" width="9" height="9"/>
									<xsl:text> </xsl:text>
									<xsl:value-of select="@name"/>
								</th>
								<td align="right" class="xform-close-button">
									<input type="image" src="{$context}/wcf/form/cancel.png" value="{../@cancel-title}" name="{../@cancel-id}" width="9" height="9"/>
								</td>
							</tr>
						</table>
					</xsl:when>
					<xsl:otherwise>
						<img src="{$context}/{$imgpath2}/{@icon}" width="9" height="9"/>
						<xsl:text> </xsl:text>
						<xsl:value-of select="@name"/>
					</xsl:otherwise>
				</xsl:choose-->
			</th>
		</tr>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="cat-item">
		<tr>
			<td class="navi-hier" style="padding-left:15px">
				<xsl:choose>
					<xsl:when test="@id">
						<a href="#" onclick="return drillNavigator('{$token}&amp;{@id}=x&amp;pivotPart=navi',false,false)">
							<xsl:value-of select="@name"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@name"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates select="slicer-value"/>
			</td>
			<td class="navi-hier" nowrap="nowrap" width="1%">
				<xsl:apply-templates select="move-button"/>
			</td>
			<td class="navi-hier" nowrap="nowrap" width="1%" valign="top">
				<xsl:apply-templates select="cat-button"/>
				<xsl:apply-templates select="property-button"/>
				<xsl:apply-templates select="function-button"/>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="slicer-value">
		<xsl:text> (</xsl:text>
		<xsl:value-of select="@level"/>
		<xsl:text> = </xsl:text>
		<xsl:value-of select="@label"/>
		<xsl:text>) </xsl:text>
	</xsl:template>
	
	<xsl:template match="cat-button[@icon]">
		<input border="0" type="image" src="{$context}/{$imgpath2}/{@icon}" name="{@id}" width="9" height="9" class="imgButton"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="cat-button">
		<img src="{$context}/{$imgpath2}/empty.png" width="9" height="9"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="property-button">
		<input border="0" type="image" src="{$context}/{$imgpath2}/properties.png" name="{@id}" class="imgButton"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="function-button">
		<input border="0" type="image" src="{$context}/{$imgpath2}/functions.png" name="{@id}" class="imgButton"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
</xsl:stylesheet>