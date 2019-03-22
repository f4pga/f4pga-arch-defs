module rom #
(
parameter  ROM_SIZE_BITS = 9    // Size in 32-bit words
)
(
// Closk & reset
input  wire CLK,
input  wire RST,

// ROM interface
input  wire                     I_STB,
input  wire [ROM_SIZE_BITS-1:0] I_ADR,

output wire         O_STB,
output wire [31:0]  O_DAT
);

// ============================================================================
localparam ROM_SIZE = (1<<ROM_SIZE_BITS);

reg [31:0] rom [0:ROM_SIZE-1];

reg        rom_stb;
reg [31:0] rom_dat;

always @(posedge CLK)
    rom_dat <= rom[I_ADR];

always @(posedge CLK or posedge RST)
    if (RST) rom_stb <= 1'd0;
    else     rom_stb <= I_STB;

assign O_STB = rom_stb;
assign O_DAT = rom_dat;

// ============================================================================

initial begin
    rom['h0000] <= 32'h00000001;
    rom['h0001] <= 32'h00020003;
    rom['h0002] <= 32'h00040005;
    rom['h0003] <= 32'h00060007;
    rom['h0004] <= 32'h00080009;
    rom['h0005] <= 32'h000A000B;
    rom['h0006] <= 32'h000C000D;
    rom['h0007] <= 32'h000E000F;
    rom['h0008] <= 32'h00100011;
    rom['h0009] <= 32'h00120013;
    rom['h000A] <= 32'h00140015;
    rom['h000B] <= 32'h00160017;
    rom['h000C] <= 32'h00180019;
    rom['h000D] <= 32'h001A001B;
    rom['h000E] <= 32'h001C001D;
    rom['h000F] <= 32'h001E001F;
    rom['h0010] <= 32'h00200021;
    rom['h0011] <= 32'h00220023;
    rom['h0012] <= 32'h00240025;
    rom['h0013] <= 32'h00260027;
    rom['h0014] <= 32'h00280029;
    rom['h0015] <= 32'h002A002B;
    rom['h0016] <= 32'h002C002D;
    rom['h0017] <= 32'h002E002F;
    rom['h0018] <= 32'h00300031;
    rom['h0019] <= 32'h00320033;
    rom['h001A] <= 32'h00340035;
    rom['h001B] <= 32'h00360037;
    rom['h001C] <= 32'h00380039;
    rom['h001D] <= 32'h003A003B;
    rom['h001E] <= 32'h003C003D;
    rom['h001F] <= 32'h003E003F;
    rom['h0020] <= 32'h00400041;
    rom['h0021] <= 32'h00420043;
    rom['h0022] <= 32'h00440045;
    rom['h0023] <= 32'h00460047;
    rom['h0024] <= 32'h00480049;
    rom['h0025] <= 32'h004A004B;
    rom['h0026] <= 32'h004C004D;
    rom['h0027] <= 32'h004E004F;
    rom['h0028] <= 32'h00500051;
    rom['h0029] <= 32'h00520053;
    rom['h002A] <= 32'h00540055;
    rom['h002B] <= 32'h00560057;
    rom['h002C] <= 32'h00580059;
    rom['h002D] <= 32'h005A005B;
    rom['h002E] <= 32'h005C005D;
    rom['h002F] <= 32'h005E005F;
    rom['h0030] <= 32'h00600061;
    rom['h0031] <= 32'h00620063;
    rom['h0032] <= 32'h00640065;
    rom['h0033] <= 32'h00660067;
    rom['h0034] <= 32'h00680069;
    rom['h0035] <= 32'h006A006B;
    rom['h0036] <= 32'h006C006D;
    rom['h0037] <= 32'h006E006F;
    rom['h0038] <= 32'h00700071;
    rom['h0039] <= 32'h00720073;
    rom['h003A] <= 32'h00740075;
    rom['h003B] <= 32'h00760077;
    rom['h003C] <= 32'h00780079;
    rom['h003D] <= 32'h007A007B;
    rom['h003E] <= 32'h007C007D;
    rom['h003F] <= 32'h007E007F;
    rom['h0040] <= 32'h00800081;
    rom['h0041] <= 32'h00820083;
    rom['h0042] <= 32'h00840085;
    rom['h0043] <= 32'h00860087;
    rom['h0044] <= 32'h00880089;
    rom['h0045] <= 32'h008A008B;
    rom['h0046] <= 32'h008C008D;
    rom['h0047] <= 32'h008E008F;
    rom['h0048] <= 32'h00900091;
    rom['h0049] <= 32'h00920093;
    rom['h004A] <= 32'h00940095;
    rom['h004B] <= 32'h00960097;
    rom['h004C] <= 32'h00980099;
    rom['h004D] <= 32'h009A009B;
    rom['h004E] <= 32'h009C009D;
    rom['h004F] <= 32'h009E009F;
    rom['h0050] <= 32'h00A000A1;
    rom['h0051] <= 32'h00A200A3;
    rom['h0052] <= 32'h00A400A5;
    rom['h0053] <= 32'h00A600A7;
    rom['h0054] <= 32'h00A800A9;
    rom['h0055] <= 32'h00AA00AB;
    rom['h0056] <= 32'h00AC00AD;
    rom['h0057] <= 32'h00AE00AF;
    rom['h0058] <= 32'h00B000B1;
    rom['h0059] <= 32'h00B200B3;
    rom['h005A] <= 32'h00B400B5;
    rom['h005B] <= 32'h00B600B7;
    rom['h005C] <= 32'h00B800B9;
    rom['h005D] <= 32'h00BA00BB;
    rom['h005E] <= 32'h00BC00BD;
    rom['h005F] <= 32'h00BE00BF;
    rom['h0060] <= 32'h00C000C1;
    rom['h0061] <= 32'h00C200C3;
    rom['h0062] <= 32'h00C400C5;
    rom['h0063] <= 32'h00C600C7;
    rom['h0064] <= 32'h00C800C9;
    rom['h0065] <= 32'h00CA00CB;
    rom['h0066] <= 32'h00CC00CD;
    rom['h0067] <= 32'h00CE00CF;
    rom['h0068] <= 32'h00D000D1;
    rom['h0069] <= 32'h00D200D3;
    rom['h006A] <= 32'h00D400D5;
    rom['h006B] <= 32'h00D600D7;
    rom['h006C] <= 32'h00D800D9;
    rom['h006D] <= 32'h00DA00DB;
    rom['h006E] <= 32'h00DC00DD;
    rom['h006F] <= 32'h00DE00DF;
    rom['h0070] <= 32'h00E000E1;
    rom['h0071] <= 32'h00E200E3;
    rom['h0072] <= 32'h00E400E5;
    rom['h0073] <= 32'h00E600E7;
    rom['h0074] <= 32'h00E800E9;
    rom['h0075] <= 32'h00EA00EB;
    rom['h0076] <= 32'h00EC00ED;
    rom['h0077] <= 32'h00EE00EF;
    rom['h0078] <= 32'h00F000F1;
    rom['h0079] <= 32'h00F200F3;
    rom['h007A] <= 32'h00F400F5;
    rom['h007B] <= 32'h00F600F7;
    rom['h007C] <= 32'h00F800F9;
    rom['h007D] <= 32'h00FA00FB;
    rom['h007E] <= 32'h00FC00FD;
    rom['h007F] <= 32'h00FE00FF;
    rom['h0080] <= 32'h01000101;
    rom['h0081] <= 32'h01020103;
    rom['h0082] <= 32'h01040105;
    rom['h0083] <= 32'h01060107;
    rom['h0084] <= 32'h01080109;
    rom['h0085] <= 32'h010A010B;
    rom['h0086] <= 32'h010C010D;
    rom['h0087] <= 32'h010E010F;
    rom['h0088] <= 32'h01100111;
    rom['h0089] <= 32'h01120113;
    rom['h008A] <= 32'h01140115;
    rom['h008B] <= 32'h01160117;
    rom['h008C] <= 32'h01180119;
    rom['h008D] <= 32'h011A011B;
    rom['h008E] <= 32'h011C011D;
    rom['h008F] <= 32'h011E011F;
    rom['h0090] <= 32'h01200121;
    rom['h0091] <= 32'h01220123;
    rom['h0092] <= 32'h01240125;
    rom['h0093] <= 32'h01260127;
    rom['h0094] <= 32'h01280129;
    rom['h0095] <= 32'h012A012B;
    rom['h0096] <= 32'h012C012D;
    rom['h0097] <= 32'h012E012F;
    rom['h0098] <= 32'h01300131;
    rom['h0099] <= 32'h01320133;
    rom['h009A] <= 32'h01340135;
    rom['h009B] <= 32'h01360137;
    rom['h009C] <= 32'h01380139;
    rom['h009D] <= 32'h013A013B;
    rom['h009E] <= 32'h013C013D;
    rom['h009F] <= 32'h013E013F;
    rom['h00A0] <= 32'h01400141;
    rom['h00A1] <= 32'h01420143;
    rom['h00A2] <= 32'h01440145;
    rom['h00A3] <= 32'h01460147;
    rom['h00A4] <= 32'h01480149;
    rom['h00A5] <= 32'h014A014B;
    rom['h00A6] <= 32'h014C014D;
    rom['h00A7] <= 32'h014E014F;
    rom['h00A8] <= 32'h01500151;
    rom['h00A9] <= 32'h01520153;
    rom['h00AA] <= 32'h01540155;
    rom['h00AB] <= 32'h01560157;
    rom['h00AC] <= 32'h01580159;
    rom['h00AD] <= 32'h015A015B;
    rom['h00AE] <= 32'h015C015D;
    rom['h00AF] <= 32'h015E015F;
    rom['h00B0] <= 32'h01600161;
    rom['h00B1] <= 32'h01620163;
    rom['h00B2] <= 32'h01640165;
    rom['h00B3] <= 32'h01660167;
    rom['h00B4] <= 32'h01680169;
    rom['h00B5] <= 32'h016A016B;
    rom['h00B6] <= 32'h016C016D;
    rom['h00B7] <= 32'h016E016F;
    rom['h00B8] <= 32'h01700171;
    rom['h00B9] <= 32'h01720173;
    rom['h00BA] <= 32'h01740175;
    rom['h00BB] <= 32'h01760177;
    rom['h00BC] <= 32'h01780179;
    rom['h00BD] <= 32'h017A017B;
    rom['h00BE] <= 32'h017C017D;
    rom['h00BF] <= 32'h017E017F;
    rom['h00C0] <= 32'h01800181;
    rom['h00C1] <= 32'h01820183;
    rom['h00C2] <= 32'h01840185;
    rom['h00C3] <= 32'h01860187;
    rom['h00C4] <= 32'h01880189;
    rom['h00C5] <= 32'h018A018B;
    rom['h00C6] <= 32'h018C018D;
    rom['h00C7] <= 32'h018E018F;
    rom['h00C8] <= 32'h01900191;
    rom['h00C9] <= 32'h01920193;
    rom['h00CA] <= 32'h01940195;
    rom['h00CB] <= 32'h01960197;
    rom['h00CC] <= 32'h01980199;
    rom['h00CD] <= 32'h019A019B;
    rom['h00CE] <= 32'h019C019D;
    rom['h00CF] <= 32'h019E019F;
    rom['h00D0] <= 32'h01A001A1;
    rom['h00D1] <= 32'h01A201A3;
    rom['h00D2] <= 32'h01A401A5;
    rom['h00D3] <= 32'h01A601A7;
    rom['h00D4] <= 32'h01A801A9;
    rom['h00D5] <= 32'h01AA01AB;
    rom['h00D6] <= 32'h01AC01AD;
    rom['h00D7] <= 32'h01AE01AF;
    rom['h00D8] <= 32'h01B001B1;
    rom['h00D9] <= 32'h01B201B3;
    rom['h00DA] <= 32'h01B401B5;
    rom['h00DB] <= 32'h01B601B7;
    rom['h00DC] <= 32'h01B801B9;
    rom['h00DD] <= 32'h01BA01BB;
    rom['h00DE] <= 32'h01BC01BD;
    rom['h00DF] <= 32'h01BE01BF;
    rom['h00E0] <= 32'h01C001C1;
    rom['h00E1] <= 32'h01C201C3;
    rom['h00E2] <= 32'h01C401C5;
    rom['h00E3] <= 32'h01C601C7;
    rom['h00E4] <= 32'h01C801C9;
    rom['h00E5] <= 32'h01CA01CB;
    rom['h00E6] <= 32'h01CC01CD;
    rom['h00E7] <= 32'h01CE01CF;
    rom['h00E8] <= 32'h01D001D1;
    rom['h00E9] <= 32'h01D201D3;
    rom['h00EA] <= 32'h01D401D5;
    rom['h00EB] <= 32'h01D601D7;
    rom['h00EC] <= 32'h01D801D9;
    rom['h00ED] <= 32'h01DA01DB;
    rom['h00EE] <= 32'h01DC01DD;
    rom['h00EF] <= 32'h01DE01DF;
    rom['h00F0] <= 32'h01E001E1;
    rom['h00F1] <= 32'h01E201E3;
    rom['h00F2] <= 32'h01E401E5;
    rom['h00F3] <= 32'h01E601E7;
    rom['h00F4] <= 32'h01E801E9;
    rom['h00F5] <= 32'h01EA01EB;
    rom['h00F6] <= 32'h01EC01ED;
    rom['h00F7] <= 32'h01EE01EF;
    rom['h00F8] <= 32'h01F001F1;
    rom['h00F9] <= 32'h01F201F3;
    rom['h00FA] <= 32'h01F401F5;
    rom['h00FB] <= 32'h01F601F7;
    rom['h00FC] <= 32'h01F801F9;
    rom['h00FD] <= 32'h01FA01FB;
    rom['h00FE] <= 32'h01FC01FD;
    rom['h00FF] <= 32'h01FE01FF;
    rom['h0100] <= 32'h02000201;
    rom['h0101] <= 32'h02020203;
    rom['h0102] <= 32'h02040205;
    rom['h0103] <= 32'h02060207;
    rom['h0104] <= 32'h02080209;
    rom['h0105] <= 32'h020A020B;
    rom['h0106] <= 32'h020C020D;
    rom['h0107] <= 32'h020E020F;
    rom['h0108] <= 32'h02100211;
    rom['h0109] <= 32'h02120213;
    rom['h010A] <= 32'h02140215;
    rom['h010B] <= 32'h02160217;
    rom['h010C] <= 32'h02180219;
    rom['h010D] <= 32'h021A021B;
    rom['h010E] <= 32'h021C021D;
    rom['h010F] <= 32'h021E021F;
    rom['h0110] <= 32'h02200221;
    rom['h0111] <= 32'h02220223;
    rom['h0112] <= 32'h02240225;
    rom['h0113] <= 32'h02260227;
    rom['h0114] <= 32'h02280229;
    rom['h0115] <= 32'h022A022B;
    rom['h0116] <= 32'h022C022D;
    rom['h0117] <= 32'h022E022F;
    rom['h0118] <= 32'h02300231;
    rom['h0119] <= 32'h02320233;
    rom['h011A] <= 32'h02340235;
    rom['h011B] <= 32'h02360237;
    rom['h011C] <= 32'h02380239;
    rom['h011D] <= 32'h023A023B;
    rom['h011E] <= 32'h023C023D;
    rom['h011F] <= 32'h023E023F;
    rom['h0120] <= 32'h02400241;
    rom['h0121] <= 32'h02420243;
    rom['h0122] <= 32'h02440245;
    rom['h0123] <= 32'h02460247;
    rom['h0124] <= 32'h02480249;
    rom['h0125] <= 32'h024A024B;
    rom['h0126] <= 32'h024C024D;
    rom['h0127] <= 32'h024E024F;
    rom['h0128] <= 32'h02500251;
    rom['h0129] <= 32'h02520253;
    rom['h012A] <= 32'h02540255;
    rom['h012B] <= 32'h02560257;
    rom['h012C] <= 32'h02580259;
    rom['h012D] <= 32'h025A025B;
    rom['h012E] <= 32'h025C025D;
    rom['h012F] <= 32'h025E025F;
    rom['h0130] <= 32'h02600261;
    rom['h0131] <= 32'h02620263;
    rom['h0132] <= 32'h02640265;
    rom['h0133] <= 32'h02660267;
    rom['h0134] <= 32'h02680269;
    rom['h0135] <= 32'h026A026B;
    rom['h0136] <= 32'h026C026D;
    rom['h0137] <= 32'h026E026F;
    rom['h0138] <= 32'h02700271;
    rom['h0139] <= 32'h02720273;
    rom['h013A] <= 32'h02740275;
    rom['h013B] <= 32'h02760277;
    rom['h013C] <= 32'h02780279;
    rom['h013D] <= 32'h027A027B;
    rom['h013E] <= 32'h027C027D;
    rom['h013F] <= 32'h027E027F;
    rom['h0140] <= 32'h02800281;
    rom['h0141] <= 32'h02820283;
    rom['h0142] <= 32'h02840285;
    rom['h0143] <= 32'h02860287;
    rom['h0144] <= 32'h02880289;
    rom['h0145] <= 32'h028A028B;
    rom['h0146] <= 32'h028C028D;
    rom['h0147] <= 32'h028E028F;
    rom['h0148] <= 32'h02900291;
    rom['h0149] <= 32'h02920293;
    rom['h014A] <= 32'h02940295;
    rom['h014B] <= 32'h02960297;
    rom['h014C] <= 32'h02980299;
    rom['h014D] <= 32'h029A029B;
    rom['h014E] <= 32'h029C029D;
    rom['h014F] <= 32'h029E029F;
    rom['h0150] <= 32'h02A002A1;
    rom['h0151] <= 32'h02A202A3;
    rom['h0152] <= 32'h02A402A5;
    rom['h0153] <= 32'h02A602A7;
    rom['h0154] <= 32'h02A802A9;
    rom['h0155] <= 32'h02AA02AB;
    rom['h0156] <= 32'h02AC02AD;
    rom['h0157] <= 32'h02AE02AF;
    rom['h0158] <= 32'h02B002B1;
    rom['h0159] <= 32'h02B202B3;
    rom['h015A] <= 32'h02B402B5;
    rom['h015B] <= 32'h02B602B7;
    rom['h015C] <= 32'h02B802B9;
    rom['h015D] <= 32'h02BA02BB;
    rom['h015E] <= 32'h02BC02BD;
    rom['h015F] <= 32'h02BE02BF;
    rom['h0160] <= 32'h02C002C1;
    rom['h0161] <= 32'h02C202C3;
    rom['h0162] <= 32'h02C402C5;
    rom['h0163] <= 32'h02C602C7;
    rom['h0164] <= 32'h02C802C9;
    rom['h0165] <= 32'h02CA02CB;
    rom['h0166] <= 32'h02CC02CD;
    rom['h0167] <= 32'h02CE02CF;
    rom['h0168] <= 32'h02D002D1;
    rom['h0169] <= 32'h02D202D3;
    rom['h016A] <= 32'h02D402D5;
    rom['h016B] <= 32'h02D602D7;
    rom['h016C] <= 32'h02D802D9;
    rom['h016D] <= 32'h02DA02DB;
    rom['h016E] <= 32'h02DC02DD;
    rom['h016F] <= 32'h02DE02DF;
    rom['h0170] <= 32'h02E002E1;
    rom['h0171] <= 32'h02E202E3;
    rom['h0172] <= 32'h02E402E5;
    rom['h0173] <= 32'h02E602E7;
    rom['h0174] <= 32'h02E802E9;
    rom['h0175] <= 32'h02EA02EB;
    rom['h0176] <= 32'h02EC02ED;
    rom['h0177] <= 32'h02EE02EF;
    rom['h0178] <= 32'h02F002F1;
    rom['h0179] <= 32'h02F202F3;
    rom['h017A] <= 32'h02F402F5;
    rom['h017B] <= 32'h02F602F7;
    rom['h017C] <= 32'h02F802F9;
    rom['h017D] <= 32'h02FA02FB;
    rom['h017E] <= 32'h02FC02FD;
    rom['h017F] <= 32'h02FE02FF;
    rom['h0180] <= 32'h03000301;
    rom['h0181] <= 32'h03020303;
    rom['h0182] <= 32'h03040305;
    rom['h0183] <= 32'h03060307;
    rom['h0184] <= 32'h03080309;
    rom['h0185] <= 32'h030A030B;
    rom['h0186] <= 32'h030C030D;
    rom['h0187] <= 32'h030E030F;
    rom['h0188] <= 32'h03100311;
    rom['h0189] <= 32'h03120313;
    rom['h018A] <= 32'h03140315;
    rom['h018B] <= 32'h03160317;
    rom['h018C] <= 32'h03180319;
    rom['h018D] <= 32'h031A031B;
    rom['h018E] <= 32'h031C031D;
    rom['h018F] <= 32'h031E031F;
    rom['h0190] <= 32'h03200321;
    rom['h0191] <= 32'h03220323;
    rom['h0192] <= 32'h03240325;
    rom['h0193] <= 32'h03260327;
    rom['h0194] <= 32'h03280329;
    rom['h0195] <= 32'h032A032B;
    rom['h0196] <= 32'h032C032D;
    rom['h0197] <= 32'h032E032F;
    rom['h0198] <= 32'h03300331;
    rom['h0199] <= 32'h03320333;
    rom['h019A] <= 32'h03340335;
    rom['h019B] <= 32'h03360337;
    rom['h019C] <= 32'h03380339;
    rom['h019D] <= 32'h033A033B;
    rom['h019E] <= 32'h033C033D;
    rom['h019F] <= 32'h033E033F;
    rom['h01A0] <= 32'h03400341;
    rom['h01A1] <= 32'h03420343;
    rom['h01A2] <= 32'h03440345;
    rom['h01A3] <= 32'h03460347;
    rom['h01A4] <= 32'h03480349;
    rom['h01A5] <= 32'h034A034B;
    rom['h01A6] <= 32'h034C034D;
    rom['h01A7] <= 32'h034E034F;
    rom['h01A8] <= 32'h03500351;
    rom['h01A9] <= 32'h03520353;
    rom['h01AA] <= 32'h03540355;
    rom['h01AB] <= 32'h03560357;
    rom['h01AC] <= 32'h03580359;
    rom['h01AD] <= 32'h035A035B;
    rom['h01AE] <= 32'h035C035D;
    rom['h01AF] <= 32'h035E035F;
    rom['h01B0] <= 32'h03600361;
    rom['h01B1] <= 32'h03620363;
    rom['h01B2] <= 32'h03640365;
    rom['h01B3] <= 32'h03660367;
    rom['h01B4] <= 32'h03680369;
    rom['h01B5] <= 32'h036A036B;
    rom['h01B6] <= 32'h036C036D;
    rom['h01B7] <= 32'h036E036F;
    rom['h01B8] <= 32'h03700371;
    rom['h01B9] <= 32'h03720373;
    rom['h01BA] <= 32'h03740375;
    rom['h01BB] <= 32'h03760377;
    rom['h01BC] <= 32'h03780379;
    rom['h01BD] <= 32'h037A037B;
    rom['h01BE] <= 32'h037C037D;
    rom['h01BF] <= 32'h037E037F;
    rom['h01C0] <= 32'h03800381;
    rom['h01C1] <= 32'h03820383;
    rom['h01C2] <= 32'h03840385;
    rom['h01C3] <= 32'h03860387;
    rom['h01C4] <= 32'h03880389;
    rom['h01C5] <= 32'h038A038B;
    rom['h01C6] <= 32'h038C038D;
    rom['h01C7] <= 32'h038E038F;
    rom['h01C8] <= 32'h03900391;
    rom['h01C9] <= 32'h03920393;
    rom['h01CA] <= 32'h03940395;
    rom['h01CB] <= 32'h03960397;
    rom['h01CC] <= 32'h03980399;
    rom['h01CD] <= 32'h039A039B;
    rom['h01CE] <= 32'h039C039D;
    rom['h01CF] <= 32'h039E039F;
    rom['h01D0] <= 32'h03A003A1;
    rom['h01D1] <= 32'h03A203A3;
    rom['h01D2] <= 32'h03A403A5;
    rom['h01D3] <= 32'h03A603A7;
    rom['h01D4] <= 32'h03A803A9;
    rom['h01D5] <= 32'h03AA03AB;
    rom['h01D6] <= 32'h03AC03AD;
    rom['h01D7] <= 32'h03AE03AF;
    rom['h01D8] <= 32'h03B003B1;
    rom['h01D9] <= 32'h03B203B3;
    rom['h01DA] <= 32'h03B403B5;
    rom['h01DB] <= 32'h03B603B7;
    rom['h01DC] <= 32'h03B803B9;
    rom['h01DD] <= 32'h03BA03BB;
    rom['h01DE] <= 32'h03BC03BD;
    rom['h01DF] <= 32'h03BE03BF;
    rom['h01E0] <= 32'h03C003C1;
    rom['h01E1] <= 32'h03C203C3;
    rom['h01E2] <= 32'h03C403C5;
    rom['h01E3] <= 32'h03C603C7;
    rom['h01E4] <= 32'h03C803C9;
    rom['h01E5] <= 32'h03CA03CB;
    rom['h01E6] <= 32'h03CC03CD;
    rom['h01E7] <= 32'h03CE03CF;
    rom['h01E8] <= 32'h03D003D1;
    rom['h01E9] <= 32'h03D203D3;
    rom['h01EA] <= 32'h03D403D5;
    rom['h01EB] <= 32'h03D603D7;
    rom['h01EC] <= 32'h03D803D9;
    rom['h01ED] <= 32'h03DA03DB;
    rom['h01EE] <= 32'h03DC03DD;
    rom['h01EF] <= 32'h03DE03DF;
    rom['h01F0] <= 32'h03E003E1;
    rom['h01F1] <= 32'h03E203E3;
    rom['h01F2] <= 32'h03E403E5;
    rom['h01F3] <= 32'h03E603E7;
    rom['h01F4] <= 32'h03E803E9;
    rom['h01F5] <= 32'h03EA03EB;
    rom['h01F6] <= 32'h03EC03ED;
    rom['h01F7] <= 32'h03EE03EF;
    rom['h01F8] <= 32'h03F003F1;
    rom['h01F9] <= 32'h03F203F3;
    rom['h01FA] <= 32'h03F403F5;
    rom['h01FB] <= 32'h03F603F7;
    rom['h01FC] <= 32'h03F803F9;
    rom['h01FD] <= 32'h03FA03FB;
    rom['h01FE] <= 32'h03FC03FD;
    rom['h01FF] <= 32'h03FE03FF;
end
endmodule

