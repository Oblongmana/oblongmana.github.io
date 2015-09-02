---
layout: post
title: "Validating ABNs and ACNs"
excerpt: "Validating ABNs and ACNs in both Salesforce Apex and T-SQL"
category: articles
tags: [salesforce, apex, tsql, ABN, ACN, ARBN, validation]
comments: true
---

One would have thought that validating Australian Company Numbers [ACN], Australian Business Numbers [ABN], and Australian Registered Body Numbers [ARBN - same thing as ACNs with a slightly different use]
would be a thoroughly solved problem - but apparently not! The actual validation is not exactly complex from a mathematical perspective, but why waste time
working out how to do it and coding it? I've recently needed to work my way through to [fairly] robust solutions for Salesforce Apex and T-SQL,
and thought I'd try to help save any intrepid Googlers some time and consternation at not being able to find a quick solution they can just drop in.

If you're wondering what Apex is and how you got here because you were looking for a Java solution - Apex is very Java-like, so you should have little trouble adapting this.

If you feel liking sinking the time in, you might be able to make these more efficient - I've tried to focus on clarity instead however! If you have any specific questions or this does something embarrassing like fail to compile, please leave a comment or ping me on Twitter.

<a href="https://gist.github.com/Oblongmana/6121504/download" target="_blank" class="btn" style="display:block; text-align:center">
    <i class="icon-github"></i> Click here to download the Gist discussed in this article
</a>


## Prefer to Skip Ahead? ##

- [Salesforce Apex](#salesforce-apex)
- [T-SQL](#t-sql)



## Salesforce Apex ##

This is a class exposing 3 static methods - Validate[ABN&#124;ACN&#124;ARBN] - each taking the number to validate in as a String. The methods first make a cursory clean of your input, only stripping whitespace and ensuring the string you provided is numeric, then trying to fail as early as possible, so they do feature multiple return points. You may wish to extend this by stripping out other characters such as dashes - this is all down to the context you're using it in really - my focus was verifying data that is supposed to be pretty clean already.

{% highlight java %}
public with sharing class ACNandABNValidation {
    private enum ValidationType {ACN, ABN}
    
    static final List<Long> ACN_WEIGHTS = new List<Long>{8,7,6,5,4,3,2,1};
    static final List<Long> ABN_WEIGHTS = new List<Long>{10,1,3,5,7,9,11,13,15,17,19};

    public static Boolean ValidateACN(String acnString) {
        acnString = getNonBlankNumericStringWithoutWhitespace(acnString);
        if(acnString == null) {
            return false;
        }

        if(acnString.length() != 9) {
            return false;
        }

        Integer strLength = acnString.length();
        Long givenCheck = Long.valueOf(acnString.substring(strLength - 1,strLength));
        Long acnWeightSum = calcWeightingSum(ValidationType.ACN, acnString);
        Long modTenRemainder = Math.mod(acnWeightSum, 10);
        Long calcCheck = (modTenRemainder == 0) ? 0 : (10 - modTenRemainder);
        if(calcCheck != givenCheck) {
            return false;
        }

        return true;
    }


    public static Boolean ValidateABN(String abnString) {
        abnString = getNonBlankNumericStringWithoutWhitespace(abnString);
        if(abnString == null) {
            return false;
        }

        if(abnString.length() != 11) {
            return false;
        }

        if(abnString.substring(0,1) == '0') {
            return false;
        }

        String pos1Less1 = String.valueOf(Long.valueOf(abnString.substring(0,1))-1);
        String modifiedABN = String.valueOf(pos1Less1 + abnString.substring(1));
        Long abnWeightingSum = calcWeightingSum(ValidationType.ABN, modifiedABN);
        Long modEightyNineRemainder = Math.mod(abnWeightingSum, 89);
        if(modEightyNineRemainder != 0) {
            return false;
        }

        return true;
    }


    public static Boolean ValidateARBN(String arbnString) {
        return ValidateACN(arbnString);
    }


    private static Long calcWeightingSum(ValidationType valType, String theNumString) {
        List<Long> weightList = 
            (valType == ValidationType.ACN) ? ACN_WEIGHTS : ABN_WEIGHTS;
        Long weightingSum = 0;

        Integer startIndex = 0;
        Integer endIndex = (valType == ValidationType.ACN ? 7 : 10);

        for(Integer i = startIndex; i <= endIndex; i++) {
            weightingSum += 
                ( Long.valueOf(theNumString.substring(i,i+1) ) * weightList[i]);
        }
        
        return weightingSum;
    }


    private static String getNonBlankNumericStringWithoutWhitespace(String theString) {
        if(String.isBlank(theString)) {
            return null;
        }

        theString = theString.deleteWhitespace();

        if(!theString.isNumeric()) {
            return null;
        }

        return theString;
    }
    
}
{% endhighlight %}


## T-SQL ##

The focus here was a little different to the Apex - these were being extracted from a database where dashes were permitted, and whitespace appeared everywhere seemingly at random. So three UDFs are dropped if necessary then defined - VALIDATE[ABN&#124;ACN&#124;ARBN] - each of which takes in a VARCHAR(256). They strip the dashes and whitespace from your VARCHAR input, and it's pretty plain sailing from there - you'll get a BIT indicating success or failure at the end. Possible extensions depending on your use case could include breaking the big IF into smaller stages and throwing CAST('Error reason' as int) depending on the failure reason - which may help you get to grips with the particular data oddities of an unfamiliar database.

{% highlight sql %}
/*** ACN Validation ***/
IF OBJECT_ID(N'dbo.VALIDATEACN', N'FN') IS NOT NULL
    DROP FUNCTION dbo.VALIDATEACN ;
GO

CREATE FUNCTION VALIDATEACN (@acn VARCHAR(256))
RETURNS BIT
WITH RETURNS NULL ON NULL INPUT
BEGIN
    DECLARE @Outcome AS BIT ;
    SET @acn = LTRIM(RTRIM(REPLACE(REPLACE(@acn,'-',''),' ','')));
    IF(
                @acn <> ''
            AND
                @acn LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
            AND 
                LEN(@acn) = 9
            AND
                RIGHT
                (
                    10 -
                    (   
                        ( CAST( SUBSTRING( @acn, 1, 1 ) AS integer ) * 8 ) 
                        + ( CAST( SUBSTRING( @acn, 2, 1 ) AS integer ) * 7 ) 
                        + ( CAST( SUBSTRING( @acn, 3, 1 ) AS integer ) * 6 ) 
                        + ( CAST( SUBSTRING( @acn, 4, 1 ) AS integer ) * 5 ) 
                        + ( CAST( SUBSTRING( @acn, 5, 1 ) AS integer ) * 4 ) 
                        + ( CAST( SUBSTRING( @acn, 6, 1 ) AS integer ) * 3 ) 
                        + ( CAST( SUBSTRING( @acn, 7, 1 ) AS integer ) * 2 ) 
                        + ( CAST( SUBSTRING( @acn, 8, 1 ) AS integer ) * 1 ) 
                    ) 
                    % 10
                    
                    , 1
                ) 
                = 
                SUBSTRING(@acn,9,1)
            )
        Set @Outcome = 1;
    ELSE
        Set @Outcome = 0;
    
    RETURN @Outcome
END;
GO


/*** ARBN Validation: Just an alias for VALIDATEACN ***/
IF OBJECT_ID(N'dbo.VALIDATEARBN', N'FN') IS NOT NULL
    DROP FUNCTION dbo.VALIDATEARBN ;
GO

CREATE FUNCTION VALIDATEARBN (@arbn VARCHAR(256))
RETURNS BIT
WITH RETURNS NULL ON NULL INPUT
BEGIN
    RETURN dbo.VALIDATEACN(@arbn);
END;
GO


/*** ABN Validation ***/
IF OBJECT_ID(N'dbo.VALIDATEABN', N'FN') IS NOT NULL
    DROP FUNCTION dbo.VALIDATEABN ;
GO

CREATE FUNCTION VALIDATEABN (@abn VARCHAR(256))
RETURNS BIT
WITH RETURNS NULL ON NULL INPUT
BEGIN
DECLARE @Outcome AS BIT ;
    SET @abn = LTRIM(RTRIM(REPLACE(REPLACE(@abn,'-',''),' ','')));
    IF(
                @abn <> ''
            AND
                @abn LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
            AND 
                LEN(@abn) = 11
            AND
                (   
                    ( ( CAST( SUBSTRING( @abn, 1, 1 ) AS integer ) - 1 ) * 10 ) 
                    + ( CAST( SUBSTRING( @abn, 2, 1 ) AS integer ) * 1 ) 
                    + ( CAST( SUBSTRING( @abn, 3, 1 ) AS integer ) * 3 ) 
                    + ( CAST( SUBSTRING( @abn, 4, 1 ) AS integer ) * 5 ) 
                    + ( CAST( SUBSTRING( @abn, 5, 1 ) AS integer ) * 7 ) 
                    + ( CAST( SUBSTRING( @abn, 6, 1 ) AS integer ) * 9 ) 
                    + ( CAST( SUBSTRING( @abn, 7, 1 ) AS integer ) * 11 ) 
                    + ( CAST( SUBSTRING( @abn, 8, 1 ) AS integer ) * 13 ) 
                    + ( CAST( SUBSTRING( @abn, 9, 1 ) AS integer ) * 15 ) 
                    + ( CAST( SUBSTRING( @abn, 10, 1 ) AS integer ) * 17 ) 
                    + ( CAST( SUBSTRING( @abn, 11, 1 ) AS integer ) * 19 ) 
                ) % 89 
                
                = 0
            )
        Set @Outcome = 1;
    ELSE
        Set @Outcome = 0;
    
    RETURN @Outcome
END;
GO
{% endhighlight %}
