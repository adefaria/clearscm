#!/usr/bin/perl
################################################################################
#
# File:         PQA.pm
# Description:  Perl module PQA conversion routines
# Author:       Andrew@DeFaria.com
# Created:      Thu Oct  6 09:51:38 PDT 2005
# Language:     Perl
# Modifications:
#
# (c) Copyright 2005, Andrew@DeFaria.com, all rights reserved
#
################################################################################
#use strict;
use warnings;
use CQPerlExt;

package PQA;
  use File::Spec;

  require (Exporter);
  @ISA = qw (Exporter);

  @EXPORT = qw (
    @old_Prod_defect_fields
    @old_TO_defect_fields
    @new_Cont_defect_fields
    @customer_fields
    @project_fields
    %bad_chars
    AddToFieldChoiceList
    AddToProject
    CheckField
    CheckRecord
    DeleteDynamicLists
    DeleteRecords
    EndSession
    GetAllDefectRecords
    GetDefectRecord
    ProjectExists
    StartSession
    TransferAttachments
    TransferHistory
    TransferRecords
  );

  # Forwards
  sub AddToFieldChoiceList;
  sub AddToProject;
  sub CheckField;
  sub CheckRecord;
  sub DeleteDynamicLists;
  sub DeleteRecords;
  sub EndSession;
  sub GetAllDefectRecords;
  sub GetDefectRecord;
  sub ProjectExists;
  sub StartSession;
  sub TransferAttachemnts;
  sub TransferHistory;
  sub TransferRecords;

  our ($me, $verbose, $debug);
  my $abs_path;

  BEGIN {
    # Check environment variables
    $verbose    = $ENV {VERBOSE} ? "yes" : "no";
    $debug      = $ENV {DEBUG}   ? "yes" : "no";
  } # BEGIN

  use Display;
  use Logger;

  ## Exported variables ##

  # Field Definitions
  our @old_Prod_defect_fields = (
    "ActionNotes",              # SHORT_STRING
    "AdvancedFeature",          # SHORT_STRING, CONSTANT_LIST
    "Assigned_Date",            # DATE_TIME
    "AttachmentBRCM",           # ATTACHMENT_LIST
    "Audit_Log",                # MULTILINE_STRING
    "Category",                 # SHORT_STRING, CONSTANT_LIST
    "Close_Date",               # DATE_TIME
    "CommitmentLevel",          # SHORT_STRING, CONSTANT_LIST
    "CommittedDate",            # DATE_TIME
    "CommittedToProject",       # SHORT_STRING, CONSTANT_LIST
    "CustomerID",               # SHORT_STRING
    "DataPendingNote",          # MULTILINE_STRING
    "DeferredToChip",           # SHORT_STRING
    "DeferredToProject",        # SHORT_STRING, CONSTANT_LIST
    "Description",              # MULTILINE_STRING
    "DoesNotVerifyNote",        # MULTILINE_STRING
    "Entry_Type",               # SHORT_STRING, CONSTANT_LIST
    "Est_Time_To_Fix",          # SHORT_STRING
    "Fixed_In_HW_Version",      # SHORT_STRING
    "Fixed_In_Project",         # SHORT_STRING, CONSTANT_LIST
    "Fixed_In_SW_Version",      # SHORT_STRING
    "GatingItem",               # SHORT_STRING, CONSTANT_LIST
    "HUT",                      # SHORT_STRING, DYNAMIC_LIST
    "HUT_Revision",             # SHORT_STRING, CONSTANT_LIST
    "HUT_Version",              # SHORT_STRING, CONSTANT_LIST
    "History",                  # JOURNAL
    "Issue_Classification",     # SHORT_STRING, CONSTANT_LIST
    "Keywords",                 # MULTILINE_STRING, CONSTANT_LIST
    "NoteBRCMOnly",             # MULTILINE_STRING
    "NoteBugReview",            # MULTILINE_STRING
    "Note_Entry",               # MULTILINE_STRING
    "Notes_Log",                # MULTILINE_STRING
    "OEMSubmitterName",         # SHORT_STRING
    "OS",                       # CONSTANT_LIST
    "Open_Close_Status",        # SHORT_STRING, CONSTANT_LIST
    "Owner",                    # REFERENCE
    "PendingHWSWReleases",      # INT
    "Priority",                 # SHORT_STRING, CONSTANT_LIST
    "Project",                  # REFERENCE
    "Project_Name",             # SHORT_STRING, CONSTANT_LIST
    "RelatedID",                # MULTILINE_STRING
    "ReportedBy",               # SHORT_STRING, CONSTANT_LIST
    "Resolution",               # SHORT_STRING
    "ResolveNote",              # MULTILINE_STRING
    "ResolvedBy",               # REFERENCE
    "Resolved_Date",            # DATE_TIME
    "SQATestCase",              # SHORT_STRING, CONSTANT_LIST
    "Service_Pack",             # SHORT_STRING
    "Severity",                 # SHORT_STRING, CONSTANT_LIST
    "Software",                 # SHORT_STRING, CONSTANT_LIST
    "Software_Version",         # SHORT_STRING
    "Submit_Date",              # DATE_TIME
    "Submitter",                # REFERENCE
    "Symptoms",                 # MULTILINE_STRING, CONSTANT_LIST
    "TCProcedure",              # MULTILINE_STRING
    "TestBlocking",             # SHORT_STRING, CONSTANT_LIST
    "TestCaseID",               # INT
    "TestcaseComment",          # MULTILINE_STRING
    "TimeFromSubmitToVerify",   # SHORT_STRING
    "TimeSubmitToResolve",      # SHORT_STRING
    "TimeSubmitToResolve",      # SHORT_STRING
    "TimeToVerify",             # SHORT_STRING
    "Title",                    # SHORT_STRING
    "VerifiedBy",               # REFERENCE
    "VerifyNote",               # MULTILINE_STRING
    "Verified_Date",            # DATE_TIME
    "Verified_In_HW_Version",   # SHORT_STRING
    "Verified_In_SW_Version",   # SHORT_STRING
    "Visibility",               # SHORT_STRING, CONSTANT_LIST
    "VisibleTo3com",            # INT
    "VisibleToAltima",          # INT
    "VisibleToCompaq",          # INT
    "VisibleToDell",            # INT
    "customer",                 # REFERENCE
    "customer_severity",        # SHORT_STRING, CONSTANT_LIST
    "old_id",                   # SHORT_STRING, CONSTANT_LIST
  );

  # This decribes the fields in the old TO defect record
  our @old_TO_defect_fields = (
    "ActionNotes",              # SHORT_STRING
    "AdvancedFeature",          # SHORT_STRING, DYNAMIC_LIST
    "Assigned_Date",            # DATE_TIME
    "AttachmentsBRCM",          # ATTACHMENT_LIST
    "Audit_Log",                # MULTILINE_STRING
    "Category",                 # SHORT_STRING, CONSTANT_LIST
    "Close_Date",               # DATE_TIME
    "CommitmentLevel",          # SHORT_STRING, CONSTANT_LIST
    "CommittedDate",            # DATE_TIME
    "CommittedToProject",       # SHORT_STRING, DYNAMIC_LIST
    "CustomerID",               # SHORT_STRING
    "DataPendingNote",          # MULTILINE_STRING
    "DeferredToChip",           # SHORT_STRING
    "DeferredToProject",        # SHORT_STRING, DYNAMIC_LIST
    "Description",              # MULTILINE_STRING
    "DoesNotVerifyNote",        # MULTILINE_STRING
    "Entry_Type",               # SHORT_STRING, CONSTANT_LIST
    "Est_Time_To_Fix",          # SHORT_STRING
    "Fixed_In_HW_Version",      # SHORT_STRING
    "Fixed_In_Project",         # SHORT_STRING, DYNAMIC_LIST
    "Fixed_In_SW_Version",      # SHORT_STRING
    "Found_In_Project",         # SHORT_STRING, DYNAMIC_LIST
    "GatingItem",               # SHORT_STRING, CONSTANT_LIST
    "HUT",                      # SHORT_STRING, DYNAMIC_LIST
    "HUT_Revision",             # SHORT_STRING, DYNAMIC_LIST
    "HUT_Version",              # SHORT_STRING, DYNAMIC_LIST
    "Headline",                 # SHORT_STRING
    "History",                  # JOURNAL
    "Issue_Classification",     # SHORT_STRING, CONSTANT_LIST
    "Keywords",                 # MULTILINE_STRING, CONSTANT_LIST
    "NoteBRCMOnly",             # MULTILINE_STRING
    "NoteBugReview",            # MULTILINE_STRING
    "Note_Entry",               # MULTILINE_STRING
    "Notes_Log",                # MULTILINE_STRING
    "OEMSubmitterName",         # SHORT_STRING
    "OS",                       # SHORT_STRING, DYNAMIC_LIST
    "Open_Close_Status",        # SHORT_STRING, CONSTANT_LIST
    "Owner",                    # REFERENCE
    "PendingHWSWReleases",      # INT
    "Priority",                 # SHORT_STRING, CONSTANT_LIST
    "Project",                  # REFERENCE
    "ReportedBy",               # REFERENCE
    "Resolution",               # SHORT_STRING, CONSTANT_LIST
    "ResolveNote",              # MULTILINE_STRING
    "ResolvedBy",               # REFERENCE
    "Resolved_Date",            # DATE_TIME
    "SQATestCase",              # SHORT_STRING, CONSTANT_LIST
    "Service_Pack",             # SHORT_STRING, DYNAMIC_LIST
    "Severity",                 # SHORT_STRING, CONSTANT_LIST
    "Software",                 # SHORT_STRING, DYNAMIC_LIST
    "Software_Version",         # SHORT_STRING
    "Submit_Date",              # DATE_TIME
    "Submitter",                # REFERENCE
    "Symptoms",                 # MULTILINE_STRING, CONSTANT_LIST
    "TCProcedure",              # MULTILINE_STRING
    "TestBlocking",             # SHORT_STRING, CONSTANT_LIST
    "TestCaseID",               # INT
    "TestcaseComment",          # MULTILINE_STRING
    "TimeFromSubmitToVerify",   # SHORT_STRING
    "TimeSubmitToResolve",      # SHORT_STRING
    "TimeToVerify",             # SHORT_STRING
    "Title_2",                  # SHORT_STRING
    "VerifiedBy",               # REFERENCE
    "Verified_Date",            # DATE_TIME
    "Verified_In_HW_Version",   # SHORT_STRING
    "Verified_In_SW_Version",   # SHORT_STRING
    "VerifyNote",               # MULTILINE_STRING
    "Visibility",               # SHORT_STRING, DYNAMIC_LIST
    "customer",                 # REFERENCE_LIST
    "customer_severity",        # SHORT_STRING, CONSTANT_LIST
    "old_id",                   # SHORT_STRING
  );

  # This describes the fields in the new Cont Defect record
  our @new_Cont_defect_fields = (
    "ActionNotes",              # SHORT_STRING
# Prod: <not defined>, TO: <not defined> -> Cont: Active_Deferred_Status
    "Active_Deferred_Status",   # SHORT_STRING, CONSTANT_LIST
    "Advanced_Feature",         # SHORT_STRING, DYNAMIC_LIST
    "Assigned_Date",            # DATE_TIME
    "AttachmentsBRCM",          # ATTACHMENT_LIST
    "Audit_Log",                # MULTILINE_STRING
    "Board_Revision",           # SHORT_STRING, DYNAMIC_LIST
# Prod: NoteBRCMOnly, TO: NoteBRCMOnly -> Cont: Broadcom_Only_Note
    "Broadcom_Only_Note",       # MULTILINE_STRING
# Prod: NoteBugReview, TO: NoteBugReview -> Cont: Bug_Review_Note
    "Bug_Review_Note",          # MULTILINE_STRING
    "Category",                 # SHORT_STRING, CONSTANT_LIST
    "Close_Date",               # DATE_TIME
    "CommitmentLevel",          # SHORT_STRING, CONSTANT_LIST
    "CommittedDate",            # DATE_TIME
    "CommittedToProject",       # SHORT_STRING, DYNAMIC_LIST
    "CustomerID",               # SHORT_STRING
    "DataPendingNote",          # MULTILINE_STRING
    "DeferredToChip",           # SHORT_STRING
    "DeferredToProject",        # SHORT_STRING, DYNAMIC_LIST
    "Description",              # MULTILINE_STRING
    "DoesNotVerifyNote",        # MULTILINE_STRING
    "Entry_Type",               # SHORT_STRING, CONSTANT_LIST
    "Est_Time_To_Fix",          # SHORT_STRING
    "Fixed_In_HW_Version",      # SHORT_STRING
    "Fixed_In_Project",         # SHORT_STRING, DYNAMIC_LIST
    "Fixed_In_SW_Version",      # SHORT_STRING
# Prod: Project (REFERENCE), TO: Project (REFERENCE) -> Cont: Found_In_Project (REFERENCE)
    "Found_In_Project",         # REFERENCE
# Prod: <not defined>, TO: <not defined> -> Cont: Found_On_Gold
    "Found_On_Gold",            # SHORT_STRING, CONSTANT_LIST
    "Gating_Item_HW",           # SHORT_STRING, CONSTANT_LIST
# Prod: GatingItem, TO: GatingItem -> Cont: Gating_Item_SW, Gating_Item_HW
    "Gating_Item_SW",           # SHORT_STRING, CONSTANT_LIST
    "HUT",                      # SHORT_STRING, DYNAMIC_LIST
    "HUT_Revision",             # SHORT_STRING, DYNAMIC_LIST
# Prod: Title, TO: Headline -> Cont: Headline
    "Headline",                 # SHORT_STRING
    "Issue_Classification",     # SHORT_STRING, CONSTANT_LIST
    "Keywords",                 # MULTILINE_STRING, CONSTANT_LIST
# Prod: <not defined>, TO: <not defined> -> Cont: Newly_Introduce
    "Newly_Introduce",          # SHORT_STRING, CONSTANT_LIST
    "Note_Entry",               # MULTILINE_STRING
    "Notes_Log",                # MULTILINE_STRING
    "OEMSubmitterName",         # SHORT_STRING
    "OS",                       # SHORT_STRING, DYNAMIC_LIST
# Prod: <not defined>, TO: <not defined> -> Cont: Other_HUT
    "Other_HUT",                # MULTILINE_STRING
    "Owner",                    # REFERENCE
# Prod: <not defined>, TO: <not defined> -> Cont: PQATestCase
    "PQATestCase",              # SHORT_STRING, CONSTANT_LIST
    "Priority",                 # SHORT_STRING, CONSTANT_LIST
# Prod: ReportedBy, TO: ReportedBy -> Cont: Reported_By
    "Reported_By",              # REFERENCE
    "Resolution",               # SHORT_STRING, CONSTANT_LIST
    "ResolveNote",              # MULTILINE_STRING
    "ResolvedBy",               # REFERENCE
    "Resolved_Date",            # DATE_TIME
# Prod: <not defined>, TO: <not defined> -> Cont: Root_Caused
    "Root_Caused",              # SHORT_STRING, CONSTANT_LIST
# Prod: <not defined>, TO: <not defined> -> Cont: Root_Caused_Note
    "Root_Caused_Note",         # MULTILINE_STRING
    "Service_Pack",             # SHORT_STRING, DYNAMIC_LIST
    "Severity",                 # SHORT_STRING, CONSTANT_LIST
    "Software",                 # SHORT_STRING, DYNAMIC_LIST
    "Software_Version",         # SHORT_STRING
    "Submit_Date",              # DATE_TIME
    "Submitter",                # REFERENCE
    "Symptoms",                 # MULTILINE_STRING, CONSTANT_LIST
    "TCProcedure",              # MULTILINE_STRING
    "TestCaseID",               # INT
    "TestcaseComment",          # MULTILINE_STRING
    "TimeFromSubmitToVerify",   # SHORT_STRING
    "TimeSubmitToResolve",      # SHORT_STRING
    "TimeToVerify",             # SHORT_STRING
# Prod: Title_2, TO: Title_2 -> Cont: Title
    "Title",                    # SHORT_STRING
    "VerifiedBy",               # REFERENCE
    "Verified_Date",            # DATE_TIME
    "Verified_In_HW_Version",   # SHORT_STRING
    "Verified_In_SW_Version",   # SHORT_STRING
    "VerifyNote",               # MULTILINE_STRING
# Prod: <not defined>, TO: <not defined> -> Cont: <added>
    "Visibility",               # SHORT_STRING, DYNAMIC_LIST
# Prod: <not defined>, TO: <not defined> -> Cont: WorkAroundNote
    "WorkAroundNote",           # MULTILINE_STRING
    "customer",                 # REFERENCE_LIST
    "customer_severity",        # SHORT_STRING, CONSTANT_LIST
    "old_id",                   # SHORT_STRING
# Prod: <not defined>, TO: Found_In_Project -> Cont: <Deleted>
#   "Found_In_Project",         # SHORT_STRING, DYNAMIC_LIST
# Deleted fields:
#     "HUT_Version",            # SHORT_STRING, DYNAMIC_LIST
#     "Open_Close_Status",      # SHORT_STRING, CONSTANT_LIST
#     "PendingHWSWReleases",    # INT
#     "SQATestCase",            # SHORT_STRING, CONSTANT_LIST
#     "TestBlocking",           # SHORT_STRING, CONSTANT_LIST
  );

  # Customer and Project records appear in both instances of the old
  # databases as well as the new Cont database and have not changed.
  our @customer_fields = (
    "Name",                     # SHORT_STRING
    "Phone",                    # SHORT_STRING
    "Fax",                      # SHORT_STRING
    "Email",                    # SHORT_STRING
    "CallTrackingID",           # SHORT_STRING
    "Description",              # MULTILINE_STRING
    "Company",                  # SHORT_STRING
    "Attachment",               # ATTACHMENT_LIST
  );

  our @project_fields = (
    "Name",                     # SHORT_STRING
    "Description",              # MULTILINE_STRING
  );

  # Collect bad characters
  our %bad_chars;

  ## Internal variables ##
  my $login     = "<username>";
  my $password  = "<password>";
  my $db_name;

  my $id;

  my $nbr_chars = 40;
  my $half      = $nbr_chars / 2;

  # Derived from http://hotwired.lycos.com/webmonkey/reference/special_characters/
  my %char_map = (
    128 => "&#128;",
    129 => "&#129;",
    130 => "&#130;",
    131 => "&#131;",
    132 => "&#132;",
    133 => "&#133;",
    134 => "&#134;",
    135 => "&#135;",
    136 => "&#136;",
    137 => "&#137;",
    138 => "&#138;",
    139 => "&#139;",
    140 => "&#140;",
    141 => "&#141;",
    142 => "&#142;",
    143 => "&#143;",
    144 => "&#144;",
    145 => "'",         # Signal "smart quote" left
    146 => "'",         # Signal "smart quote" right
    147 => "\"",        # Double "smart quote" left
    148 => "\"",        # Double "smart quote" right
    149 => "&#149;",
    150 => "&ndash;",   # En dash
    151 => "&mdash;",   # Em dash
    152 => "&#152;",
    153 => "&#153;",
    154 => "&#154;",
    155 => "&#155;",
    156 => "&#156;",
    157 => "&#157;",
    158 => "&#158;",
    159 => "&#159;",
    160 => "&nbsp;",    # Nonbreaking space
    161 => "&iexcl;",   # Inverted exclamation (¡)
    162 => "&cent;",    # Cent sign (¢)
    163 => "&pound;",   # Pound sterling (£)
    164 => "&curren;",  # General currency sign (¤)
    165 => "&yen;",     # Yen sign (¥)
    166 => "&brkbar;",  # Broken vertical bar (¦)
    167 => "&sect;",    # Section sign (§)
    168 => "&uml;",     # Umlaut (¨)
    169 => "&copy;",    # Copyright (©)
    170 => "&ordf;",    # Feminine ordinal (ª)
    171 => "&laquo;",   # Left angle quote («)
    172 => "&not;",     # Not sign (¬)
    173 => "&shy;",     # Soft hyphen
    174 => "&reg;",     # Registered trademark (®)
    175 => "&macr;",    # Macron accent (¯)
    176 => "&deg;",     # Degree sign (°)
    177 => "&plusmn;",  # Plus or minus (±)
    178 => "&sup2;",    # Superscript two (²)
    179 => "&sup3;",    # Superscript three (³)
    180 => "&acute;",   # Acute accent (´)
    181 => "&micro;",   # Micro sign (µ)
    182 => "&para;",    # Paragraph sign (¶)
    183 => "&middot;",  # Middle dot (·)
    184 => "&cedil;",   # Cedilla (¸)
    185 => "&sup1;",    # Superscript one (¹)
    186 => "&ordm;",    # Masculine ordinal (º)
    187 => "&raquo;",   # Right angle quote (»)
    188 => "&frac14;",  # One-forth (¼)
    189 => "&frac12;",  # One-half (½)
    190 => "&frac24;",  # Three-fourths (¾)
    191 => "&iquest;",  # Inverted question mark (¿)
    192 => "&Agrave;",  # Uppercase A, grave accent (À)
    193 => "&Aacute;",  # Uppercase A, acute accent (Á)
    194 => "&Acirc;",   # Uppercase A, circumflex accent (Â)
    195 => "&Atilde;",  # Uppercase A, tilde (Ã)
    196 => "&Auml;",    # Uppercase A, umlaut (Ä)
    197 => "&Aring;",   # Uppercase A, ring (Å)
    198 => "&AElig;",   # Uppercase AE (Æ)
    199 => "&Ccedil;",  # Uppercase C, cedilla (Ç)
    200 => "&Egrave;",  # Uppercase E, grave accent (È)
    201 => "&Eacute;",  # Uppercase E, acute accent (É)
    202 => "&Ecirc;",   # Uppercase E, circumflex accent (Ê)
    203 => "&Euml;",    # Uppercase E, umlaut (Ë)
    204 => "&Igrave;",  # Uppercase I, grave accent (Ì)
    205 => "&Iacute;",  # Uppercase I, acute accent (Í)
    206 => "&Icirc;",   # Uppercase I, circumflex accent (Î)
    207 => "&Iuml;",    # Uppercase I, umlaut (Ï)
    208 => "&ETH;",     # Uppercase Eth, Icelandic (Ð)
    209 => "&Ntilde;",  # Uppercase N, tilde (Ñ)
    210 => "&Ograve;",  # Uppercase O, grave accent (Ò)
    211 => "&Oacute;",  # Uppercase O, acute accent (Ó)
    212 => "&Ocirc;",   # Uppercase O, circumflex accent (Ô)
    213 => "&Otilde;",  # Uppercase O, tilde (Õ)
    214 => "&Ouml;",    # Uppercase O, umlaut (Ö)
    215 => "&times;",   # Muliplication sign (×)
    216 => "&Oslash;",  # Uppercase O, slash (Ø)
    217 => "&Ugrave;",  # Uppercase U, grave accent (Ù)
    218 => "&Uacute;",  # Uppercase U, acute accent (Ú)
    219 => "&Ucirc;",   # Uppercase U, circumflex accent (Û)
    220 => "&Uuml;",    # Uppercase U, umlaut (Ü)
    221 => "&Yacute;",  # Uppercase Y, acute accent (Ý)
    222 => "&THORN;",   # Uppercase THORN, Icelandic (Þ)
    223 => "&szlig;",   # Lowercase sharps, German (ß)
    224 => "&agrave;",  # Lowercase a, grave accent (à)
    225 => "&aacute;",  # Lowercase a, acute accent (á)
    226 => "&acirc;",   # Lowercase a, circumflex acirc (â)
    227 => "&atilde;",  # Lowercase a, tilde (ã)
    228 => "&auml;",    # Lowercase a, umlaut (ä)
    229 => "&aring;",   # Lowercase a, ring (å)
    230 => "&aelig;",   # Lowercase ae (æ)
    231 => "&ccedil;",  # Lowercase c, cedilla (ç)
    232 => "&egrave;",  # Lowercase e, grave accent (è)
    233 => "&eacute;",  # Lowercase e, acute accent (é)
    234 => "&ecirc;",   # Lowercase e, circumflex accent (ê)
    235 => "&euml;",    # Lowercase e, umlaut (ë)
    236 => "&igrave;",  # Lowercase i, grave accent (ì)
    237 => "&iacute;",  # Lowercase i, acute accent (í)
    238 => "&icirc;",   # Lowercase i, circumflex accent (î)
    239 => "&iuml;",    # Lowercase i, umlaut (ï)
    240 => "&eth;",     # Lowercase eth, Icelandic (ð)
    241 => "&ntilde;",  # Lowercase n, tilde (ñ)
    242 => "&ograve;",  # Lowercase o, grave accent (ò)
    243 => "&oacute;",  # Lowercase o, acute accent (ó)
    244 => "&ocirc;",   # Lowercase o, circumflex accent (ô)
    245 => "&otilde;",  # Lowercase o, tilde (õ)
    246 => "&ouml;",    # Lowercase o, umlaut (ö)
    247 => "&divide;",  # Division sign (÷)
    248 => "&oslash;",  # Lowercase o, slash (ø)
    249 => "&ugrave;",  # Lowercase u, grave accent (ù)
    250 => "&uacute;",  # Lowercase u, acute accent (ú)
    251 => "&ucirc;",   # Lowercase u, circumflex accent (û)
    252 => "&uuml;",    # Lowercase u, umlaut (ü)
    253 => "&yacute;",  # Lowercase y, acute accent (ý)
    254 => "&thorn;",   # Lowercase thorn, Icelandic (þ)
    255 => "&yuml;",    # Lowercase y, umlaut (ÿ)
  );

  ## Exported functions ##
  # Add a value to a field's dynamic list
  sub AddToFieldChoiceList {
    my $session         = shift;
    my $entity          = shift;
    my $dynamic_list    = shift;
    my $name            = shift;
    my $value           = shift;

    return if $value eq "";

    # It seems that adding the entry to the dynamic list is not enough.
    # I believe that Clearquest caches entries on a dynamic list so we
    # need to tell Clearquest about this new entry.
    my $add_value  = 1;
    my @values = @{$entity->GetFieldChoiceList ($name)};

    # Ack! Seems now we have values like Service_Pack = "1.A" and
    # Service_Pack = "1.a", which translate to the same value as far
    # as a dynamic list is concerned, so we'll do the comparison
    # ignoring case... Additionally there can be regex meta characters
    # in the value so we'll need to protect from that.
    foreach (@values) {
      if ("\L$value\E" eq "\L$_\E") {
        $add_value = 0;
        last;
      } # if
    } # foreach

    if ($add_value) {
      push @values, $value;

      $entity->SetFieldChoiceList ($name, \@values);
    } # if

    # Get the current values, if any
    @values = @{$session->GetListMembers ($dynamic_list)};

    # Search to see if the item is already on the list
    foreach (@values) {
      return if ("\L$value\E" eq "\L$_\E");
    } # if

    $session->AddListMember ($dynamic_list, $value);

    push @values, $value;

    $session->SetListMembers ($dynamic_list, \@values);
  } # AddToDynamicList

  # TO: defect: Found_In_Project is currently a dynamic list but is
  # going to Cont: defect: Found_In_Project which is a reference to
  # Cont: Project. So we need to dynamically add those.
  sub AddToProject {
    my $log     = shift;
    my $to      = shift;
    my $project = shift;

    if (ProjectExists $to, $project) {
      return;
    } # if

    my $entity = $to->BuildEntity ("Project");

    $entity->SetFieldValue ("name", $project);

    # Call the Validate method
    my $errmsg = $entity->Validate;

    $log->err ("Unable to validate Project record: $project:\n$errmsg", 1) if $errmsg ne "";

    # Post record to database
    $entity->Commit if $errmsg eq "";
  } # AddToProject

  sub CheckField {
    my $log             = shift;
    my $db_name         = shift;
    my $record_name     = shift;
    my $id              = shift;
    my $field_name      = shift;
    my $str             = shift;

    return $str if length $str eq 0; # Ignore empty strings

    if ($str =~ /[^\t\n\r -\177]/) {
      for (my $x = 0; $x < length $str; $x++) {
        my $y = substr $str, $x, 1;
        if ($y =~ /[^\t\n\r -\177]/) {
          my $o = ord ($y);
          display "At char #$x found \"$y\" ($o)";
          my $s = substr $str, $x - 20, 40;
          display "\"$s\"";
        } # if
      } # for
      error "$field_name match", 1;
    } # if

    for (my $i = 0; $i < length $str; $i++) {
      my $ord = ord (substr $str, $i, 1);

      if ($ord < 0 or $ord > 127) {
        # $id is undefined at this point...
        $log->msg ("$db_name:$record_name:$id:$field_name:$i");
        $log->msg ("Old Contents:\n$str");
        $str = FixChar ($str, $i);
        $log->msg ("New Contents:\n$str");
      } # if
    } # foreach

    return $str;
  } # CheckField

  sub CheckRecord {
    my $log             = shift;
    my $session         = shift;
    my $id_name         = shift;
    my $record_name     = shift;
    my $id              = shift;
    my @fields          = @_;

    my $result;

    if (defined $id) {
      $result = GetDefectRecord $log, $session, $record_name, $id;
    } else {
      $result = GetAllDefectRecords $log, $session, $record_name;
    } # if

    while ($result->MoveNext == $CQPerlExt::CQ_SUCCESS) {
      # GetEntity by using $id
      $id               = $result->GetColumnValue (1);
      my $entity        = $session->GetEntity ($record_name, $id);

      $log->msg ($id);

      foreach (@fields) {
        my $name        = $_;
        my $value       = $entity->GetFieldValue ($name)->GetValue;

        $value = CheckField $log, $db_name, $record_name, $id, $name, $value;
      } # for
    } # for
  } # CheckRecord

  sub DeleteDynamicLists {
    my $log             = shift;
    my $from            = shift;

    my @dynamic_lists = (
      "Advanced_Feature",
      "Board_Revision",
      "HUT",
      "HUT_Revision",
      "OS",
      "OS_Service_Pack",
      "Other_HUT",
      "Project",
      "Reported_By",
      "Software",
      "Visibility",
    );

    $log->msg ("Clearing dynamic lists...");

    foreach my $name (@dynamic_lists) {
      my @values = @{$from->GetListMembers ($name)};

      foreach my $value (@values) {
        $from->DeleteListMember ($name, $value);
      } # foreach
    } # foreach
  } # DeleteDynamicLists

  sub DeleteRecords {
    my $log             = shift;
    my $from            = shift;
    my $record_name     = shift;

    # Create a query for $record_name
    my $query = $from->BuildQuery ($record_name);

    $query->BuildField ("dbid");

    # Build the result set
    my $result = $from->BuildResultSet ($query);

    # Execute the query
    my $record_count = $result->ExecuteAndCountRecords;

    $log->msg ("Found $record_count $record_name records to delete...");

    return if $record_count eq 0;

    my $old_bufffer_status = $|;
    $| = 1; # Turn off buffering

    # Now for each record returned by the query...
    while ($result->MoveNext == 1) {
      my $id = $result->GetColumnValue (1);

      # Get entity
      my $entity = $from->GetEntityByDbId ($record_name, $id);

      # Delete it
      my $errmsg = $from->DeleteEntity ($entity, "delete");

      verbose ".", undef, "nolf";
      $log->err ("\n$errmsg\n") if $errmsg ne "";
    } # while

    verbose "";

    $| = $old_bufffer_status; # Restore buffering
  } # DeleteRecords

  sub EndSession {
    my $session = shift;

    CQSession::Unbuild $session;
  } # EndSession

  sub GetAllDefectRecords {
    my $log             = shift;
    my $from            = shift;
    my $record_name     = shift;

    # Create a query for the record
    my $query = $from->BuildQuery ($record_name);

    # Add only dbid to the query. We'll retrieve the whole entity record later.
    $query->BuildField ("id");

    # Build the result set
    my $result = $from->BuildResultSet ($query);

    # Execute the query
    my $record_count = $result->ExecuteAndCountRecords;

    $log->msg ("Found $record_count $record_name records...");

    if ($record_count eq 0) {
      return undef;
    } else {
      return $result;
    } # if
  } # GetAllDefectRecords

  sub GetDefectRecord {
    my $log             = shift;
    my $from            = shift;
    my $record_name     = shift;
    my $id              = shift;

    my $query   = $from->BuildQuery ($record_name);
    my $filter  = $query->BuildFilterOperator ($CQPerlExt::AD_BOOL_OP_AND);

    $query->BuildField ("id");

    # BuildFilter requires an array reference
    my @ids;
    push @ids, $id;
    $filter->BuildFilter ("id", $CQPerlExt::CQ_COMP_OP_EQ, \@ids);

    my $result = $from->BuildResultSet ($query);
    my $record_count = $result->ExecuteAndCountRecords;

    $log->msg ("Found $record_count $record_name record...");

    if ($record_count eq 0) {
      return undef;
    } else {
      return $result;
    } # if
  } # GetDefectRecord

  sub ProjectExists {
    my $to      = shift;
    my $project = shift;

    my $query = $to->BuildQuery ("Project");

    my $filter = $query->BuildFilterOperator ($CQPerlExt::AD_BOOL_OP_AND);

    $query->BuildField  ("name");

    # BuildFilter requires an array reference
    my @projects;
    push @projects, $project;
    $filter->BuildFilter ("name", $CQPerlExt::CQ_COMP_OP_EQ, \@projects);

    my $result = $to->BuildResultSet ($query);

    my $record_count = $result->ExecuteAndCountRecords;

    return $record_count;
  } # ProjectExists

  sub StartSession {
    $db_name    = shift;
    $masterdb   = shift;

    my $session = CQPerlExt::CQSession_Build ();

    $masterdb = "" if !defined $masterdb;

    $session->UserLogon ($login, $password, $db_name, $masterdb);

    return $session;
  } # StartSession

  sub TransferAttachments {
    my $log     = shift;
    my $from    = shift;
    my $to      = shift;

    my @files_created;

    my $from_attachment_fields  = $from->GetAttachmentFields;

    for (my $i = 0; $i < $from_attachment_fields->Count; $i++) {
      my $from_attachment_field = $from_attachment_fields->Item ($i);
      my $field_name            = $from_attachment_field->GetFieldName;

      # At this point we don't have any info about whether we are
      # coming from Prod or TO, however, there are the following fields:
      #
      #          TO                    Prod                   Cont
      # ----------------------- ----------------------- ----------------
      # Attachments             Attachments             Attachments
      # AttachmentsBRCM         AttachmentBRCM          AttachmentsBRCM
      #
      # You may notice that Prod: AttachmentBRCM is missing the "s".
      # Therefore:
      $field_name = "AttachmentsBRCM" if $field_name eq "AttachmentBRCM";

      my $from_attachments      = $from_attachment_field->GetAttachments;

      my $filename_suffix = 0;

      for (my $j = 0; $j < $from_attachments->Count; $j++) {
        my $from_attachment     = $from_attachments->Item ($j);
        my $description         = $from_attachment->GetDescription;
        my $filename            = $from_attachment->GetFileName;

        debug "Processing attachment #$j: $filename: $description";

        # Extract the attached file to the file named attachment;
        # Argh! Sometimes people attach files with the same filename!
        # This works because filename is not really used except when
        # you initially load the file. So the user could have, for
        # example, captured say a logfile.txt, attached it,
        # regenerated a new logfile.txt and attached it! This is
        # perfectly acceptable since logfile.txt is copied into the
        # database. However, when we extract it here we just use
        # $filename. The result is that the second logfile.txt
        # overwrites the first logfile.txt! We need to check for
        # clashes (only a handful of them) and generate a new
        # filename.
        if (-f $filename) {
          $filename_suffix++;
          $filename = "$filename.$filename_suffix";
        } # if

        $from_attachment->Load ($filename);

        $to->AddAttachmentFieldValue ($field_name, $filename, $description);

        push @files_created, $filename;
      } # for
    } # for

    return @files_created;
  } # TransferAttachments

  sub TransferHistory {
    my $from_entity     = shift;
    my $to_entity       = shift;
    my $filename        = shift;

    my $history_fields          = $from_entity->GetHistoryFields;
    my $nbr_history_fields      = $history_fields->Count;

    return if $nbr_history_fields eq 0;

    for (my $i = 0; $i < $nbr_history_fields; $i++) {
      my $histories     = $history_fields->Item ($i)->GetHistories;
      my $nbr_histories = $histories->Count;

      return if $nbr_histories eq 0;

      # Write out history to History.txt
      open HISTORY, ">$filename"
        or error "Unable to open $filename", 1;

      print HISTORY "Previous History:\n";
      print HISTORY "-----------------\n";

      for (my $j = 0; $j < $nbr_histories; $j++) {
        my $history_item        = $histories->Item ($j);
        my $history_value       = $history_item->GetValue;

        # Remove dbid
        $history_value =~ /\S*\s*(.*$)/;
        print HISTORY "$1\n";
      } # for

      close HISTORY;
    } # for

    # Add previous history as an AttachmentsBRCM
    $to_entity->AddAttachmentFieldValue ("AttachmentsBRCM", $filename, "Previous history");
  } # TransferHistory

  sub TransferRecords {
    my $log             = shift;
    my $from            = shift;
    my $to              = shift;
    my $dbname          = shift;
    my $record_name     = shift;
    my @field_list      = @_;

    # Create a query for the record
    my $query = $from->BuildQuery ($record_name);

    # Always get the $id_name field
    $query->BuildField ("dbid");

    # Add all of @field_list to the query
    foreach (@field_list) {
      $query->BuildField ($_);
    } # foreach

    # Build the result set
    my $result = $from->BuildResultSet ($query);

    # Execute the query
    my $record_count = $result->ExecuteAndCountRecords;

    verbose "Found $record_count $record_name records to merge...";

    return if $record_count eq 0;

    my $old_bufffer_status = $|;
    $| = 1; # Turn off buffering

    # Now for each record returned by the query...
    while ($result->MoveNext == 1) {
      # Create a new entity
      my $entity = $to->BuildEntity ($record_name);

      my $cols = $result->GetNumberOfColumns;

      my $id = $result->GetColumnValue (1);

      # Get the fields...
      for (my $i = 2; $i <= $cols; $i++) {
        my $name  = $result->GetColumnLabel ($i);
        my $value = $result->GetColumnValue ($i);

        # Check field for non US ASCII characters and fix them
        $value = CheckField $dbname, $record_name, $id, $name, $value;

        # Set the field's value
        $entity->SetFieldValue ($name, $value);
      } # for

      # Call the Validate method
      my $errmsg = $entity->Validate;

      $log->err ("Unable to validate $record_name record:\n$errmsg", 1) if $errmsg ne "";

      # Post record to database
      $entity->Commit;
      verbose ".", undef, "nolf";
    } # while

    $| = $old_bufffer_status; # Restore buffering
    verbose " done";
  } # TransferRecords

  # Internal functions
  sub DisplayWord {
    my $str     = shift;
    my $start   = shift;

    my $ord             = ord (substr $str, $start, 1);
    my $end             = $start;
    my $orig_start      = $start;

    # Let's just show a small subset of characters
    if (length $str < $nbr_chars) {
      $end   = length $str;
      $start = 0;
    } elsif (($start + $half) > length $str) {
      $end = length $str;
      my $right = length $str - $start;
      if (($start - ($half + ($half - $right))) lt 0) {
        $start = 0;
      } else {
        $start = $start - ($half + $right);
      } # if
    } elsif (($start - $half) < 0) {
      $start = 0;
      if ($start + ($half + $start) gt length $str) {
        $end = length $str;
      } else {
        $end = $start + ($half + $start);
      } # if
    } else {
      $end   = $start + $half;
      $start = $start - $half;
    } # if

    my $word = substr $str, $start, $end - $start;

    debug "\t@ pos $orig_start ($ord)\n\t\"$word\"\n";
  } # DisplayWord

  sub FixChar {
    my $str     = shift;
    my $pos     = shift;

    my $ord     = ord (substr $str, $pos, 1);

    error "Unknown character found ($ord) \"" . substr ($str, $pos, 1) . "\"", 1
      if (!defined $char_map {$ord});

    if ($debug eq "yes") {
      debug "Before:\n";
      DisplayWord $str, $pos;
    } # if

    substr ($str, $pos, 1) = $char_map {$ord};

    if ($debug eq "yes") {
       debug "After:\n";
      DisplayWord $str, $pos;
    } # if

    return $str;
  } # FixChar

1;
