/*
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution, if
 *    any, must include the following acknowlegement:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowlegement may appear in the software itself,
 *    if and wherever such third-party acknowlegements normally appear.
 *
 * 4. The names "Ant" and "Apache Software
 *    Foundation" must not be used to endorse or promote products derived
 *    from this software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache"
 *    nor may "Apache" appear in their names without prior written
 *    permission of the Apache Group.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 */

&GLOBAL-DEFINE SEPARATOR '|'
&GLOBAL-DEFINE SEPARATOR2 '*'

DEFINE TEMP-TABLE CRCList NO-UNDO
  FIELD ttTable AS CHARACTER
  FIELD ttCRC   AS CHARACTER
  INDEX ttCRC-PK IS PRIMARY UNIQUE ttTable.
DEFINE TEMP-TABLE TimeStamps NO-UNDO
  FIELD ttFile     AS CHARACTER CASE-SENSITIVE
  FIELD ttFullPath AS CHARACTER CASE-SENSITIVE
  FIELD ttMod      AS INTEGER
  INDEX PK-TimeStamps IS PRIMARY UNIQUE ttFile.
DEFINE TEMP-TABLE ttXref NO-UNDO
    FIELD xProcName   AS CHARACTER
    FIELD xFileName   AS CHARACTER
    FIELD xLineNumber AS CHARACTER
    FIELD xRefType    AS CHARACTER
    FIELD xObjID      AS CHARACTER FORMAT "X(50)"
    index typ is primary xRefType.
DEFINE TEMP-TABLE ttDirs NO-UNDO
    FIELD baseDir AS CHARACTER
    FIELD dirName AS CHARACTER.

FUNCTION getTimeStampDF RETURN INTEGER (INPUT d AS CHARACTER, INPUT f AS CHARACTER) FORWARD.
FUNCTION getTimeStampF RETURN INTEGER (INPUT f AS CHARACTER) FORWARD.
FUNCTION getDate RETURNS INTEGER (INPUT dt AS DATE, INPUT tm AS INTEGER) FORWARD.
FUNCTION CheckIncludes RETURNS LOGICAL  (INPUT f AS CHARACTER, INPUT TS AS INTEGER) FORWARD.
FUNCTION CheckCRC RETURNS LOGICAL (INPUT f AS CHARACTER) FORWARD.
FUNCTION FileExists RETURNS LOGICAL (INPUT f AS CHARACTER) FORWARD.
FUNCTION createDir RETURNS LOGICAL (INPUT base AS CHARACTER, INPUT d AS CHARACTER) FORWARD.

/** Named streams */
DEFINE STREAM sXref.
DEFINE STREAM sXref2.
DEFINE STREAM sIncludes.
DEFINE STREAM sCRC.

/** Parameters from ANT call */
DEFINE VARIABLE MinSize   AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE MD5       AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE ForceComp AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE NoComp    AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE keepXref  AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE RunList   AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE lXCode    AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE XCodeKey  AS CHARACTER  NO-UNDO INITIAL ?.
DEFINE VARIABLE Languages AS CHARACTER  NO-UNDO INITIAL ?.
DEFINE VARIABLE gwtFact   AS INTEGER    NO-UNDO INITIAL 100.
DEFINE VARIABLE multiComp AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE streamIO  AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE lV6Frame  AS LOGICAL    NO-UNDO INITIAL FALSE.
DEFINE VARIABLE lRelative AS LOGICAL    NO-UNDO INITIAL FALSE.

PROCEDURE getCRC:
    DEFINE INPUT  PARAMETER cPrm AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER opOK AS LOGICAL     NO-UNDO.
    DEFINE OUTPUT PARAMETER opMsg AS CHARACTER NO-UNDO.

    /* Gets CRC list */
	DEFINE VARIABLE h AS HANDLE     NO-UNDO.
	h = TEMP-TABLE CRCList:HANDLE.
	RUN pct/pctCRC.p (INPUT-OUTPUT TABLE-HANDLE h) NO-ERROR.
    ASSIGN opOK = (RETURN-VALUE EQ '0').
    
END PROCEDURE.

PROCEDURE setOptions:
    DEFINE INPUT  PARAMETER ipPrm AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER opOK  AS LOGICAL     NO-UNDO.
    DEFINE OUTPUT PARAMETER opMsg AS CHARACTER NO-UNDO.

    /* Defines compilation option -- This is a ';' separated string containing */
    /* runList (LOG), minSize (LOG), md5 (LOG), xcode (LOG), xcodekey (CHAR), forceCompil (LOG), noCompil (LOG), keepXref (LOG), multiComp (LOG), streamIO (LOG), lV6Frame (LOG) */
    ASSIGN runList   = ENTRY(1, ipPrm, ';') EQ 'true'
           minSize   = ENTRY(2, ipPrm, ';') EQ 'true'
           md5       = ENTRY(3, ipPrm, ';') EQ 'true'
           lXCode    = ENTRY(4, ipPrm, ';') EQ 'true'
           xcodekey  = ENTRY(5, ipPrm, ';')
           forceComp = ENTRY(6, ipPrm, ';') EQ 'true'
           noComp    = ENTRY(7, ipPrm, ';') EQ 'true'
           keepXref  = ENTRY(8, ipPrm, ';') EQ 'true'
           languages = (IF ENTRY(9, ipPrm, ';') EQ '' THEN ? ELSE ENTRY(9, ipPrm, ';'))
           gwtFact   = INTEGER(ENTRY(10, ipPrm, ';'))
           multiComp = ENTRY(11, ipPrm, ';') EQ 'true'
           streamIO  = ENTRY(12, ipPrm, ';') EQ 'true'
           lV6Frame  = ENTRY(13, ipPrm, ';') EQ 'true'
           lRelative = ENTRY(14, ipPrm, ';') EQ 'true' NO-ERROR.

    ASSIGN opOk = (ERROR-STATUS:ERROR EQ FALSE).

END PROCEDURE.

PROCEDURE pctCompile:
    DEFINE INPUT  PARAMETER ipPrm AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER opOK  AS LOGICAL     NO-UNDO INITIAL FALSE.
    DEFINE OUTPUT PARAMETER opMsg AS CHARACTER NO-UNDO.

    /* Input parameter is a #-separated list of compilation units */
    /* Each compilation unit is a pipe-separated list of infos : */
    /*  -> Fileset directory - Full pathname (CHAR) */
    /*  -> Input file directory - relative path */
    /*  -> Input file to compile - just the file name (CHAR) */
    /*  -> Base output dir - Full path name (CHAR) */
    /*  -> Output dir for compiled file (CHAR) */
    /*  -> Debug listing file (CHAR) - Empty to disable generation */
    /*  -> Preprocessor file (CHAR) - Empty to disable generation */
    /*  -> Listing file (CHAR) - Empty to disable generation */
    /*  -> xref file (CHAR) */
    /*  -> PCT dir (CHAR) - */
    /*  -> Target file name (CHAR) */
    DEFINE VARIABLE fsRootDir   AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE fsDir       AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE fsFile      AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE destDir     AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE outputDir   AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE dbgList     AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE prepro      AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE listingFile AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE xrefFile    AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE pctDir      AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE targetFile  AS CHARACTER  NO-UNDO.

    DEFINE VARIABLE zz  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE filesNum AS INTEGER     NO-UNDO.
    DEFINE VARIABLE compOK AS INTEGER     NO-UNDO.
    DEFINE VARIABLE compNotOK AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cc  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE lOK AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE lSkipped AS LOGICAL     NO-UNDO.

    COMPILER:MULTI-COMPILE = multiComp.

    ASSIGN filesNum = NUM-ENTRIES(ipPrm, {&SEPARATOR2}).
    DO zz = 1 TO filesNum:
        ASSIGN cc = ENTRY(zz, ipPrm, {&SEPARATOR2}).

        ASSIGN fsRootDir   = ENTRY(1, cc, {&SEPARATOR})
               fsDir       = ENTRY(2, cc, {&SEPARATOR})
               fsFile      = ENTRY(3, cc, {&SEPARATOR})
               destDir     = ENTRY(4, cc, {&SEPARATOR})
               outputDir   = ENTRY(5, cc, {&SEPARATOR})
               dbgList     = ENTRY(6, cc, {&SEPARATOR})
               prepro      = ENTRY(7, cc, {&SEPARATOR})
               listingFile = ENTRY(8, cc, {&SEPARATOR})
               xrefFile    = ENTRY(9, cc, {&SEPARATOR})
               pctDir      = ENTRY(10, cc, {&SEPARATOR})
               targetFile  = ENTRY(11, cc, {&SEPARATOR}).
        /* Setting to null if needed */
        ASSIGN dbgList     = (IF dbgList EQ '' THEN ? ELSE dbgList)
               prepro      = (IF prepro EQ '' THEN ? ELSE prepro)
               listingFile = (IF listingFile EQ '' THEN ? ELSE listingFile)
               xrefFile    = (IF xrefFile EQ '' THEN ? ELSE xrefFile)
               targetFile  = (IF targetFile EQ '' THEN ? ELSE targetFile).

      RUN pctCompile2 (SOURCE-PROCEDURE, fsRootDir, fsDir, fsFile, destDir, outputDir, dbgList, prepro, listingFile, xrefFile, pctDir, targetFile, OUTPUT lOK, OUTPUT lSkipped).
      IF (lok EQ TRUE) THEN
        ASSIGN compOK = compOK + (IF lSkipped THEN 0 ELSE 1).
      ELSE
        ASSIGN compNotOk = compNotOK + 1.      
    END.
   
    ASSIGN opOK = (compNotOk EQ 0)
           opMsg = STRING(compOK) + "/" + STRING(compNotOk).

END PROCEDURE.

FUNCTION getRecompileLabel RETURNS CHARACTER (ipVal AS INTEGER):
  CASE ipVal:
    WHEN 1 THEN RETURN 'Compilation forced or using XCODE'.
    WHEN 2 THEN RETURN 'No r-code in build directory'.
    WHEN 3 THEN RETURN 'R-code is older than source code'.
    WHEN 4 THEN RETURN 'An include file changed'.
    WHEN 5 THEN RETURN 'Table CRC changed'.
    OTHERWISE RETURN 'Unknown'.
  END.
END FUNCTION.

/* Return value of this procedure follows this pattern :
 *  OK:
 *  -1 if not recompiled, 0 if compilation successful, or the numbers of compilation problems
 *  Zero to n lines of compiler output
 */
PROCEDURE pctCompile2 PRIVATE:
    DEFINE INPUT PARAM ipSrcProc   AS HANDLE     NO-UNDO.
    DEFINE INPUT PARAM fsRootDir   AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM fsDir       AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM fsFile      AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM baseDir     AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM outputDir   AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM dbgList     AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM prepro      AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM listingFile AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM xrefFile    AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM pctDir      AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAM targetFile  AS CHARACTER  NO-UNDO.
    DEFINE OUTPUT PARAM opOK AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAM opSkipped AS LOGICAL NO-UNDO INITIAL FALSE.

    DEFINE VARIABLE Recompile AS INTEGER NO-UNDO INITIAL 0.

    DEFINE VARIABLE FileExt   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE RCodeName AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE RCodeTS   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE ProcTS    AS INTEGER     NO-UNDO.
    DEFINE VARIABLE zz        AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cBase     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cFile     AS CHARACTER   NO-UNDO.

    IF (ForceComp OR lXCode) THEN DO:
        ASSIGN Recompile = 1.
    END.
    ELSE DO:
        /* Checking .r file exists */
        RUN adecomm/_osfext.p(fsFile, OUTPUT FileExt).
        ASSIGN RCodeName = SUBSTRING(fsFile, 1, R-INDEX(fsFile, FileExt) - 1) + '.r':U.
        ASSIGN RCodeTS = getTimeStampDF(baseDir + '/' + fsDir, RCodeName).
        IF (RCodeTS EQ ?) THEN DO:
          ASSIGN Recompile = 2.
        END.
        ELSE DO:
            /* Checking .r timestamp is prior procedure timestamp */
            ASSIGN ProcTS = getTimeStampDF(fsRootDir + '/' + fsDir, fsFile).
            IF (ProcTS GT RCodeTS) THEN DO:
              ASSIGN Recompile = 3.
            END.
            ELSE DO:
                /* Checking included files */
                IF (CheckIncludes(PCTDir + '.inc', RCodeTS)) THEN DO:
                    ASSIGN Recompile = 4.
                END.
                ELSE DO:
                    /* Checking CRC */
                    IF CheckCRC(PCTDir + '.crc') THEN ASSIGN Recompile = 5.
                END.
            END.
        END.
    END.
    
    /* FIXME Gestion de l'attribut noCompile */

    IF (Recompile GT 0) THEN DO:
        RUN logVerbose IN ipSrcProc (SUBSTITUTE("Thread &1 - Compiling &2/&3/&4 [&5]", DYNAMIC-FUNCTION('getThreadNumber' IN ipSrcProc), fsRootDir, fsDir, fsFile, getRecompileLabel(Recompile))).
        IF lXCode THEN DO:
            IF (XCodeKey NE ?) THEN
                COMPILE VALUE(IF lRelative THEN fsDir + (IF fsDir NE '' THEN '/' ELSE '') + fsFile ELSE fsRootDir + '/' + fsDir + '/' + fsFile) SAVE INTO VALUE(outputDir) STREAM-IO=streamIO V6FRAME=lV6Frame MIN-SIZE=MinSize GENERATE-MD5=MD5 XCODE XCodeKey NO-ERROR.
            ELSE
                COMPILE VALUE(IF lRelative THEN fsDir + (IF fsDir NE '' THEN '/' ELSE '') + fsFile ELSE fsRootDir + '/' + fsDir + '/' + fsFile) SAVE INTO VALUE(outputDir) STREAM-IO=streamIO V6FRAME=lV6Frame MIN-SIZE=MinSize GENERATE-MD5=MD5 NO-ERROR.
        END.
        ELSE DO:
            COMPILE VALUE(IF lRelative THEN fsDir + (IF fsDir NE '' THEN '/' ELSE '') + fsFile ELSE fsRootDir + '/' + fsDir + '/' + fsFile) SAVE INTO VALUE(outputDir) LANGUAGES (VALUE(languages)) TEXT-SEG-GROW=gwtFact STREAM-IO=streamIO V6FRAME=lV6Frame DEBUG-LIST VALUE(dbgList) PREPROCESS VALUE(prepro) LISTING VALUE(listingFile) MIN-SIZE=MinSize GENERATE-MD5=MD5 XREF VALUE(xreffile) APPEND=FALSE NO-ERROR.
        END.
        IF COMPILER:ERROR THEN DO:
            ASSIGN opOK = FALSE.

            RUN getCompileErrors(INPUT ipSrcProc, SEARCH(fsRootDir + '/' + fsDir + '/' + fsFile), SEARCH(COMPILER:FILE-NAME), COMPILER:ERROR-ROW, COMPILER:ERROR-COLUMN).
            DO zz = 1 TO ERROR-STATUS:NUM-MESSAGES:
                RUN logError IN ipSrcProc (ERROR-STATUS:GET-MESSAGE(zz)).
            END.
            RUN logWarning IN ipSrcProc (INPUT ' ').
        END.
        ELSE DO:
            ASSIGN opOK = TRUE.
            IF (targetFile NE ?) AND (RCodeName NE targetFile) THEN DO:
                OS-COPY VALUE(outputDir + "/" + RCodeName) VALUE(outputDir + "/" + targetFile).
                OS-DELETE VALUE(outputDir + "/" + RCodeName).
            END.
            RUN ImportXref (INPUT xreffile, INPUT pctdir) NO-ERROR.
            IF (NOT keepXref) THEN
                OS-DELETE VALUE(xrefFile).
        END.
        RETURN.
    END.
    ELSE DO:
        ASSIGN opOK = TRUE
               opSkipped = TRUE.
        RETURN. 
    END.
        	
END PROCEDURE.

FUNCTION CheckIncludes RETURNS LOGICAL (INPUT f AS CHARACTER, INPUT TS AS INTEGER).
    DEFINE VARIABLE IncFile     AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE IncFullPath AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE lReturn     AS LOGICAL    NO-UNDO INITIAL FALSE.

    IF NOT fileExists(f) THEN
        RETURN TRUE.
    INPUT STREAM sIncludes FROM VALUE (f).
    FileList:
    REPEAT:
        IMPORT STREAM sIncludes IncFile IncFullPath.
        FIND TimeStamps WHERE TimeStamps.ttFile EQ IncFile NO-LOCK NO-ERROR.
        IF (NOT AVAILABLE TimeStamps) THEN DO:
            CREATE TimeStamps.
            ASSIGN TimeStamps.ttFile = IncFile
                   TimeStamps.ttFullPath = SEARCH(IncFile).
            ASSIGN TimeStamps.ttMod = getTimeStampF(TimeStamps.ttFullPath).
        END.
        IF (TimeStamps.ttFullPath NE IncFullPath) OR (TS LT TimeStamps.ttMod) THEN DO:
            ASSIGN lReturn = TRUE.
            LEAVE FileList.
        END.
    END.
    INPUT STREAM sIncludes CLOSE.
    RETURN lReturn.

END FUNCTION.

FUNCTION CheckCRC RETURNS LOGICAL (INPUT f AS CHARACTER).
    DEFINE VARIABLE cTab AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cCRC AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE lRet AS LOGICAL    NO-UNDO INITIAL FALSE.

    IF NOT fileExists(f) THEN
        RETURN TRUE.
    INPUT STREAM sCRC FROM VALUE(f).
    CRCList:
    REPEAT:
        IMPORT STREAM sCRC cTab cCRC.
        FIND CRCList WHERE CRCList.ttTable EQ cTab NO-LOCK NO-ERROR.
        IF (NOT AVAILABLE CRCList) THEN DO:
            ASSIGN lRet = TRUE.
            LEAVE CRCList.
        END.
        IF (CRCList.ttCRC NE cCRC) THEN DO:
            ASSIGN lRet = TRUE.
            LEAVE CRCList.
        END.
    END.
    INPUT STREAM sCRC CLOSE.
    RETURN lRet.

END FUNCTION.

PROCEDURE getCompileErrors PRIVATE:
    DEFINE INPUT PARAMETER ipSrcProc AS HANDLE NO-UNDO.
    DEFINE INPUT PARAMETER pcInit AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcFile AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piRow  AS INTEGER   NO-UNDO.
    DEFINE INPUT PARAMETER piColumn AS INTEGER   NO-UNDO.

    DEFINE VARIABLE i   AS INTEGER    NO-UNDO INITIAL 1.
    DEFINE VARIABLE c   AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE tmp AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE bit AS INTEGER NO-UNDO.
    DEFINE VARIABLE memvar AS MEMPTR NO-UNDO.
    DEFINE VARIABLE include AS LOGICAL NO-UNDO.
    
    ASSIGN include = REPLACE(pcInit, CHR(92), '/') EQ REPLACE(pcFile, CHR(92), '/').
    /* Checking if file is xcoded */
    COPY-LOB FROM FILE (IF include THEN pcInit ELSE pcFile) FOR 1 TO memvar.
    bit = GET-BYTE (memvar,1).
    SET-SIZE(memvar)= 0.
    
    IF (include) THEN
        RUN logError IN ipSrcProc (SUBSTITUTE("Error compiling file &1 at line &2 column &3", pcInit, piRow, piColumn)).
    ELSE
        RUN logError IN ipSrcProc (SUBSTITUTE("Error compiling file &1 in included file &4 at line &2 column &3", pcInit, piRow, piColumn, pcFile)).
   
    IF (bit NE 17) AND (bit NE 19) THEN DO:
        INPUT STREAM sXref FROM VALUE((IF include THEN pcInit ELSE pcFile)).
        DO i = 1 TO piRow - 1:
            IMPORT STREAM sXref UNFORMATTED tmp.
        END.
        IMPORT STREAM sXref UNFORMATTED tmp.
        RUN logError IN ipSrcProc (INPUT tmp).
        RUN logError IN ipSrcProc (INPUT FILL('-':U, piColumn - 2) + '-^').
    
        INPUT STREAM sXref CLOSE.
    END.
    ELSE
        RUN logError IN ipSrcProc (SUBSTITUTE(">> Can't display xcoded source &1", (IF pcInit EQ pcFile THEN pcInit ELSE pcFile))).
    
    RETURN c.
END PROCEDURE.

PROCEDURE importXref PRIVATE:
    DEFINE INPUT  PARAMETER pcXref AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcDir  AS CHARACTER NO-UNDO.

    DEFINE VARIABLE cSearch AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cTmp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTmp2 AS CHARACTER NO-UNDO.
    DEFINE VARIABLE zz AS INTEGER NO-UNDO.

    EMPTY TEMP-TABLE ttXref.

    INPUT STREAM sXREF FROM VALUE (pcXref).
    INPUT STREAM sXREF2 FROM VALUE (pcXref).
    REPEAT:
        CREATE ttXref.
        IMPORT STREAM sXREF ttXref.

        /* Sorry, this is crude... */
        IMPORT STREAM sXREF2 UNFORMATTED cTmp.
        ASSIGN cTmp2 = ttXref.xLineNumber + ' ' + ttXref.xRefType + ' '.
        ASSIGN ttXref.xObjID = SUBSTRING(cTmp, INDEX(cTmp, cTmp2) + LENGTH(cTmp2)).

        /* Remove surrounding quotes */
        IF (SUBSTRING(ttXref.xObjId, 1, 1) EQ '"') AND (SUBSTRING(ttXref.xObjId, LENGTH(ttXref.xObjId), 1) EQ '"') THEN
          ASSIGN ttXref.xObjId = SUBSTRING(ttXref.xObjId, 2, LENGTH(ttXref.xObjId) - 2).

          IF (ttXref.xRefType EQ 'INCLUDE':U) OR (RunList AND (ttXref.xRefType EQ 'RUN':U)) THEN
            ttXref.xObjID = ENTRY(1, TRIM(ttXref.xObjID), ' ':U).
          ELSE IF (LOOKUP(ttXref.xRefType, 'CREATE,REFERENCE,ACCESS,UPDATE,SEARCH':U) NE 0) THEN DO:
            /* xObjID may contain DB.Table followed by IndexName or FieldName. We extract table name */
            IF (INDEX(ttXref.xObjID, ' ') GT 0) THEN
                ASSIGN ttXref.xObjID = SUBSTRING(ttXref.xObjID, 1, INDEX(ttXref.xObjID, ' ') - 1).
          END.
          ELSE IF (LOOKUP(ttXref.xRefType, 'CLASS':U) EQ 0) THEN
            DELETE ttXref.
    END.
    DELETE ttXref. /* ttXref is non-undo'able */
    INPUT STREAM sXREF CLOSE.
    INPUT STREAM sXREF2 CLOSE.

    OUTPUT TO VALUE (pcdir + '.inc':U).
    FOR EACH ttXref WHERE xRefType EQ 'INCLUDE':U NO-LOCK BREAK BY ttXref.xObjID:
        IF FIRST-OF (ttXref.xObjID) THEN
            EXPORT ttXref.xObjID SEARCH(ttXref.xObjID).
    END.
    OUTPUT CLOSE.

    OUTPUT TO VALUE (pcdir + '.crc':U).
    FOR EACH ttXref WHERE LOOKUP(ttXref.xRefType, 'CREATE,REFERENCE,ACCESS,UPDATE,SEARCH':U) NE 0 NO-LOCK BREAK BY ttXref.xObjID:
        IF FIRST-OF (ttXref.xObjID) THEN DO:
            FIND CRCList WHERE CRCList.ttTable EQ ttXref.xObjID NO-LOCK NO-ERROR.
            IF (AVAILABLE CRCList) THEN DO:
                EXPORT CRCList.
            END.
        END.
    END.
    OUTPUT CLOSE.

    OUTPUT TO VALUE (pcdir + '.hierarchy':U).
    FOR EACH ttXref WHERE xRefType EQ 'CLASS':U NO-LOCK:
        ASSIGN cTmp = ENTRY(2, ttXref.xObjID).
        IF cTmp BEGINS 'INHERITS ' THEN DO:
            ASSIGN cTmp = SUBSTRING(cTmp, 10). /* To remove INHERITS */
            DO zz = 1 TO NUM-ENTRIES(cTmp, ' '):
                EXPORT ENTRY(zz, cTmp, ' ') SEARCH(REPLACE(ENTRY(zz, cTmp, ' '), '.', '/') + '.cls').
            END.
        END.
        ASSIGN cTmp = ENTRY(3, ttXref.xObjID).
        IF cTmp BEGINS 'IMPLEMENTS ' THEN DO:
            ASSIGN cTmp = SUBSTRING(cTmp, 12). /* To remove IMPLEMENTS */
            DO zz = 1 TO NUM-ENTRIES(cTmp, ' '):
                EXPORT ENTRY(zz, cTmp, ' ') SEARCH(REPLACE(ENTRY(zz, cTmp, ' '), '.', '/') + '.cls').
            END.
        END.
    END.
    OUTPUT CLOSE.

    IF RunList THEN DO:
        OUTPUT TO VALUE (pcdir + '.run':U).
        FOR EACH ttXref WHERE xRefType EQ 'RUN':U AND ((ttXref.xObjID MATCHES '*' + CHR(126) + '.p') OR (ttXref.xObjID MATCHES '*' + CHR(126) + '.w')) NO-LOCK BREAK BY ttXref.xObjID:
            IF FIRST-OF (ttXref.xObjID) THEN DO:
                FIND TimeStamps WHERE TimeStamps.ttFile EQ ttXref.xObjID NO-LOCK NO-ERROR.
                IF (NOT AVAILABLE TimeStamps) THEN DO:
                	ASSIGN cSearch = SEARCH(SUBSTRING(ttXref.xObjID, 1, R-INDEX(ttXref.xObjID, '.')) + 'r').
                	IF (cSearch EQ ?) THEN
                        ASSIGN cSearch = SEARCH(ttXref.xObjID).
                    CREATE TimeStamps.
                    ASSIGN TimeStamps.ttFile = ttXref.xObjID
                           TimeStamps.ttFullPath = (IF cSearch EQ ? THEN 'NOT FOUND' ELSE cSearch).
                    ASSIGN TimeStamps.ttMod = getTimeStampF(TimeStamps.ttFullPath).
                END.
                EXPORT ttXref.xObjID TimeStamps.ttFullPath.
            END.
        END.
        OUTPUT CLOSE.
    END.

END PROCEDURE.

FUNCTION getTimeStampDF RETURNS INTEGER(INPUT d AS CHARACTER, INPUT f AS CHARACTER):
    RETURN getTimeStampF(d + '/':U + f).
END FUNCTION.

FUNCTION getTimeStampF RETURNS INTEGER(INPUT f AS CHARACTER):
    ASSIGN FILE-INFO:FILE-NAME = f.
    RETURN getDate(FILE-INFO:FILE-MOD-DATE, FILE-INFO:FILE-MOD-TIME).
END FUNCTION.

FUNCTION getDate RETURNS INTEGER (INPUT dt AS DATE, INPUT tm AS INTEGER):
    IF (dt EQ ?) OR (tm EQ ?) THEN RETURN ?.
    RETURN (INTEGER(dt) - INTEGER(DATE(1, 1, 1990))) * 86400 + tm.
END FUNCTION.

FUNCTION fileExists RETURNS LOGICAL (INPUT f AS CHARACTER):
    ASSIGN FILE-INFO:FILE-NAME = f.
    RETURN (FILE-INFO:FULL-PATHNAME NE ?).
END FUNCTION.

FUNCTION createDir RETURNS LOGICAL (INPUT base AS CHARACTER, INPUT d AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER    NO-UNDO.
    DEFINE VARIABLE c AS CHARACTER  NO-UNDO.

    /* Asserts base is a writable directory */
    FIND ttDirs WHERE ttDirs.baseDir EQ base
                  AND ttDirs.dirName EQ d
                NO-LOCK NO-ERROR.
    IF (AVAILABLE ttDirs) THEN
        RETURN TRUE.

    ASSIGN d = REPLACE(d, CHR(92), '/':U).
    DO i = 1 TO NUM-ENTRIES(d, '/':U):
        ASSIGN c = c + '/':U + ENTRY(i, d, '/':U).
        FIND ttDirs WHERE ttDirs.baseDir EQ base
                      AND ttDirs.dirName EQ c
                    NO-LOCK NO-ERROR.
        IF (NOT AVAILABLE ttDirs) THEN DO:
            OS-CREATE-DIR VALUE(base + c).
            IF (OS-ERROR EQ 0) THEN DO:
                CREATE ttDirs.
                ASSIGN ttDirs.baseDir = base
                       ttDirs.dirName = c.
            END.
            ELSE DO:
                RETURN FALSE.
            END.
        END.
    END.
    RETURN TRUE.

END FUNCTION.
