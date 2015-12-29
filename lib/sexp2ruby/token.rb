module Sexp2Ruby
  class Token

    # Valid token types, from RubyParser.
    # See e.g. ruby_parser-3.7.2/lib/ruby_lexer.rex and
    # ruby_parser-3.7.2/lib/ruby22_parser.y
    TYPES = %i[
      k__ENCODING__ k__FILE__ k__LINE__ kALIAS kAND kBEGIN kBREAK kCASE kCLASS
      kDEF kDEFINED kDO kDO_BLOCK kDO_COND kDO_LAMBDA kELSE kELSIF kEND kENSURE
      kFALSE kFOR kIF kIF_MOD kIN klBEGIN klEND kMODULE kNEXT kNIL kNOT kOR
      kREDO kRESCUE kRESCUE_MOD kRETRY kRETURN kSELF kSUPER kTHEN kTRUE kUNDEF
      kUNLESS kUNLESS_MOD kUNTIL kUNTIL_MOD kWHEN kWHILE kWHILE_MOD kYIELD
      tAMPER tAMPER2 tANDOP tAREF tASET tASSOC tBACK_REF tBACK_REF2 tBANG tCARET
      tCHAR tCMP tCOLON tCOLON2 tCOLON3 tCOMMA tCONSTANT tCVAR tDIVIDE tDOT
      tDOT2 tDOT3 tDSTAR tEH tEQ tEQQ tFID tFLOAT tGEQ tGT tGVAR tIDENTIFIER
      tIMAGINARY tINTEGER tIVAR tLABEL tLABEL_END tLAMBDA tLAMBEG tLBRACE
      tLBRACE_ARG tLBRACK tLBRACK2 tLCURLY tLEQ tLPAREN tLPAREN2 tLPAREN_ARG
      tLSHFT tLT tMATCH tMINUS tNEQ tNL tNMATCH tNTH_REF tOP_ASGN tOROP tPERCENT
      tPIPE tPLUS tPOW tQSYMBOLS_BEG tQWORDS_BEG tRATIONAL tRBRACK tRCURLY
      tREGEXP_BEG tREGEXP_END tRPAREN tRSHFT tSEMI tSPACE tSTAR tSTAR2 tSTRING
      tSTRING_BEG tSTRING_CONTENT tSTRING_DBEG tSTRING_DEND tSTRING_DVAR
      tSTRING_END tSYMBEG tSYMBOL tSYMBOLS_BEG tTILDE tUBANG tUMINUS tUMINUS_NUM
      tUPLUS tWORDS_BEG tXSTRING_BEG
    ]

    # Tokens after which a line break would not end the statement.
    CAN_BREAK_AFTER = %i[tDOT tLPAREN]

    # Tokens before which a line break would not end the statement.
    CAN_BREAK_BEFORE = %i[tRPAREN]

    attr_reader :type

    def initialize(type, value)
      unless TYPES.include?(type)
        raise ArgumentError, "Invalid token type: #{type}"
      end
      @type = type
      @value = value
    end

    def can_break_after?
      CAN_BREAK_AFTER.include?(@type)
    end

    def can_break_before?
      CAN_BREAK_BEFORE.include?(@type)
    end

    def to_s
      @value.to_s
    end
  end
end
