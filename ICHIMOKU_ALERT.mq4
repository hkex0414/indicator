//+------------------------------------------------------------------+
//|                                               ICHIMOKU_ALERT.mq4 |
//|                                      Copyright 2019, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

//-----インジゲーター設定------
// 表示場所
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1 Red

//---------------------------

//--------ENUM定義-----------
// Pascal方式
// MA算出方式
enum TaMethodList
{
   SMA = 0,  // 単純移動平均線
   EMA = 1,  // 指数移動平均線
   SMMA = 2, // 平滑移動平均線
   LWMA = 3  // 線形加重移動平均戦
};
// チャート時間軸
enum TimeFrameList
{
   Current_timeFrame = 0, // 現在の時間足
   M1 = 1,                // 1分足
   M5 = 5,                // 5分足
   M15 = 15,              // 15分足
   M30 = 30,              // 30分足
   H1 = 60,               // 1時間足
   H4 = 240,              // 4時間足
   D1 = 1440,             // 日足
   W1 = 10080,            //週足
   MN = 43200             // 月足
};
// 価格データ
enum AppliedPriceList
{
   CLOSE = 0,   // 終値
   OPEN = 1,    // 始値
   HIGH = 2,    // 高値
   LOW = 3,     // 安値
   MEDIAN = 4,  // 中央値
   TYPICAL = 5, // 代表値
   WEIGHTED = 6 // 加重終値
};
//---------------------------

//------パラメーター定義------
// Pascal方式
// MTF用
// int MtfTimeFrameId;
// extern TimeFrameList MtfTimeFrameId = Current_timeFrame; // MTFで表示させる時間軸
extern int MaShift = 26; // 遅行スパンのズラす期間
//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
//---------------------------

//----------配列定義---------
// Camel方式
double tikouSpan[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, tikouSpan);
   SetindexShift(0, -MaShift);

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   return (0)
}
//+------------------------------------------------------------------+
//| Custom indicator start function                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // ループ上限
   int limit = Bars - IndicatorCounted();
   // 足が更新されたかの判定
   bool isNewCandle = Time[0] != b4Time && limit == 2;

   for (int i = limit - 1; i >= 0; i--)
   {
      //インジ計算処理
      tikouSpan[i] = Close[i];
   }
   return (rates_total);
}
