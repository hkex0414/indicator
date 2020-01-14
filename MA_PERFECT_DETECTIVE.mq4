//+------------------------------------------------------------------+
//|                                              range_detective.mq4 |
//|                                       Copyright 2019, 崩れかけた家 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict
#property indicator_chart_window
#property indicator_color1 DodgerBlue
#property indicator_color2 HotPink
#property indicator_color3 Blue
#property indicator_color4 Red

// MA用バッファ
double Ema62[];
double Sma144[];
double Sma200[];
double Sma800[];

extern bool IsPushNotify = True; // Push通知とアラートのオンオフ

string ReminingTime_sname = "bars_remining_time";
extern bool RemainingTimeEnabled = True; // 確定までの時間を表示する
extern double LocationX = 1050;          // 確定までの残り時間を表示する場所（X座標）
extern double LocationY = 20;            // 確定までの残り時間を表示する場所（Y座標）
extern int FontSize = 20;                // 確定までの残り時間を表示する文字サイズ
extern color FontColor = White;          // 確定までの残り時間を表示する文字色

bool b4IsSellPerfect, b4IsBuyPerfect;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  //--- indicator buffers mapping
  SetIndexBuffer(0, Ema62);
  SetIndexBuffer(1, Sma144);
  SetIndexBuffer(2, Sma200);
  SetIndexBuffer(3, Sma800);
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
  ObjectDelete(ReminingTime_sname);
  return (0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
  //---
  int countedBar = IndicatorCounted();
  int limit = Bars - countedBar;

  for (int i = limit - 1; i >= 0; i--)
  {
    Ema62[i] = iMA(NULL, 0, 62, 0, MODE_EMA, PRICE_CLOSE, i);
    Sma144[i] = iMA(NULL, 0, 144, 0, MODE_SMA, PRICE_CLOSE, i);
    Sma200[i] = iMA(NULL, 0, 200, 0, MODE_SMA, PRICE_CLOSE, i);
    Sma800[i] = iMA(NULL, 0, 800, 0, MODE_SMA, PRICE_CLOSE, i);
  }

  double nowEma62 = iMA(NULL, 0, 62, 0, MODE_EMA, PRICE_CLOSE, 0);
  double nowSma144 = iMA(NULL, 0, 144, 0, MODE_SMA, PRICE_CLOSE, 0);
  double nowSma200 = iMA(NULL, 0, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
  double nowSma800 = iMA(NULL, 0, 800, 0, MODE_SMA, PRICE_CLOSE, 0);

  double nowEma62pips = PriceToPips(nowEma62);
  double nowSma144pips = PriceToPips(nowSma144);
  double nowSma200pips = PriceToPips(nowSma144);
  double nowSma800pips = PriceToPips(nowSma144);

  bool isBuyPerfect = nowEma62pips < nowSma144pips < nowSma200pips;
  bool isSellPerfect = nowEma62pips > nowSma144pips > nowSma200pips;

  if (IsPushNotify)
  {
    // 買いパーフェクトオーダー
    if (!b4IsBuyPerfect && isBuyPerfect)
    {
      SendNotification(Symbol() + "BuyPerfectOrderRush.");
      Alert(Symbol() + "BuyPerfectOrderRush.");
    }
    if (b4IsBuyPerfect && !isBuyPerfect)
    {
      SendNotification(Symbol() + "BuyPerfectOrderBreak.");
      Alert(Symbol() + "BuyPerfectOrderBreak.");
    }
    // 売りパーフェクトオーダー
    if (!b4IsBuyPerfect && isSellPerfect)
    {
      SendNotification(Symbol() + "SellPerfectOrderRush.");
      Alert(Symbol() + "SellPerfectOrderRush.");
    }
    if (b4IsBuyPerfect && !isSellPerfect)
    {
      SendNotification(Symbol() + "SellPerfectOrderBreak.");
      Alert(Symbol() + "SellPerfectOrderBreak.");
    }
  }

  // 前回ループ値
  b4IsBuyPerfect = isBuyPerfect;
  b4IsSellPerfect = isSellPerfect;

  double g;
  int m, s, k, h;
  m = Time[0] + Period() * 60 - TimeCurrent();
  g = m / 60.0;
  s = m % 60;
  m = (m - m % 60) / 60;

  string text;

  if (Period() <= PERIOD_H1)
  {
    text = "残り " + m + " 分 " + s + " 秒";
  }
  else
  {
    if (m >= 60)
      h = m / 60;
    else
      h = 0;
    k = m - (h * 60);
    text = "残り " + h + " 時間 " + k + " 分 " + s + " 秒";
  }

  if (RemainingTimeEnabled)
  {
    ObjectCreate(ReminingTime_sname, OBJ_LABEL, 0, 0, 0);
    ObjectSetText(ReminingTime_sname, text, FontSize, "Terminal", FontColor);
    ObjectSet(ReminingTime_sname, OBJPROP_XDISTANCE, LocationX);
    ObjectSet(ReminingTime_sname, OBJPROP_YDISTANCE, LocationY);
  }

  //--- return value of prev_calculated for next call
  return (rates_total);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 価格をpipsに換算
//+------------------------------------------------------------------+
double PriceToPips(double price)
{
  double pips = 0;

  // 現在の通貨ペアの小数点以下の桁数を取得
  int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

  // 3桁・5桁の通貨ペアの場合
  if (digits == 3 || digits == 5)
  {
    pips = price * MathPow(10, digits) / 10;
  }
  // 2桁・4桁の通貨ペアの場合
  if (digits == 2 || digits == 4)
  {
    pips = price * MathPow(10, digits);
  }
  // 少数点以下を１桁に丸める
  pips = NormalizeDouble(pips, 1);

  return (pips);
}