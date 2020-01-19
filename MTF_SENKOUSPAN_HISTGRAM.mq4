#property copyright "www,forex-tsd.com"
#property link "www,forex-tsd.com"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 LimeGreen
#property indicator_color2 Red
#property indicator_color3 Gold
#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 3
#property indicator_minimum 0
#property indicator_maximum 1

//
//
//
//
//

extern string TimeFrame = "Current time frame";
extern int Tenkan = 9;
extern int Kijun = 26;
extern int Senkou = 52;
extern bool ShowNeutral = false;

extern bool alertsOn = true;
extern bool alertsOnCurrent = false;
extern bool alertsMessage = true;
extern bool alertsSound = false;
extern bool alertsEmail = false;
extern string soundfile = "alert2.wav";

//
//
//
//
//

double UpH[];
double DnH[];
double NuH[];
double Tenkan_Buffer[];
double Kijun_Buffer[];
double SpanA_Buffer[];
double SpanB_Buffer[];
double trend[];

//
//
//
//
//

string indicatorFileName;
int timeFrame;
bool returnBars;
bool calculateValue;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   IndicatorBuffers(8);
   SetIndexBuffer(0, UpH);
   SetIndexStyle(0, DRAW_HISTOGRAM);
   SetIndexBuffer(1, DnH);
   SetIndexStyle(1, DRAW_HISTOGRAM);
   SetIndexBuffer(2, NuH);
   SetIndexStyle(2, DRAW_HISTOGRAM);
   SetIndexBuffer(3, Tenkan_Buffer);
   SetIndexBuffer(4, Kijun_Buffer);
   SetIndexBuffer(5, SpanA_Buffer);
   SetIndexBuffer(6, SpanB_Buffer);
   SetIndexBuffer(7, trend);

   //
   //
   //
   //
   //

   indicatorFileName = WindowExpertName();
   calculateValue = (TimeFrame == "calculateValue");
   if (calculateValue)
      return (0);
   returnBars = (TimeFrame == "returnBars");
   if (returnBars)
      return (0);
   timeFrame = stringToTimeFrame(TimeFrame);
   SetIndexShift(0, Kijun * timeFrame / Period());
   SetIndexShift(1, Kijun * timeFrame / Period());
   SetIndexShift(2, Kijun * timeFrame / Period());
   SetIndexShift(5, Kijun * timeFrame / Period());
   SetIndexShift(6, Kijun * timeFrame / Period());

   //
   //
   //
   //
   //

   IndicatorShortName(timeFrameToString(timeFrame) + "  SpanA-SpanB Cross Histo");
   return (0);
}

int deinit() { return (0); }

//
//
//
//
//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

int start()
{
   int counted_bars = IndicatorCounted();
   int i, k, limit;

   if (counted_bars < 0)
      return (-1);
   if (counted_bars > 0)
      counted_bars--;
   limit = MathMin(Bars - counted_bars, Bars - 1);
   if (returnBars)
   {
      UpH[0] = limit + 1;
      return (0);
   }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      for (i = limit; i >= 0; i--)
      {

         double thi = High[i];
         double tlo = Low[i];
         double tprice = 0;
         if (i >= Bars - Tenkan)
            continue;
         for (k = 0; k < Tenkan; k++)
         {
            tprice = High[i + k];
            if (thi < tprice)
               thi = tprice;

            tprice = Low[i + k];
            if (tlo > tprice)
               tlo = tprice;
         }

         if ((thi + tlo) > 0.0)
            Tenkan_Buffer[i] = (thi + tlo) / 2;
         else
            Tenkan_Buffer[i] = 0;

         //
         //
         //
         //
         //

         double khi = High[i];
         double klo = Low[i];
         double kprice = 0;
         if (i >= Bars - Kijun)
            continue;
         for (k = 0; k < Kijun; k++)
         {
            kprice = High[i + k];
            if (khi < kprice)
               khi = kprice;

            kprice = Low[i + k];
            if (klo > kprice)
               klo = kprice;
         }

         if ((khi + klo) > 0.0)
            Kijun_Buffer[i] = (khi + klo) / 2;
         else
            Kijun_Buffer[i] = 0;

         //
         //
         //
         //
         //

         double shi = High[i];
         double slo = Low[i];
         double sprice = 0;
         if (i >= Bars - Senkou)
            continue;
         for (k = 0; k < Senkou; k++)
         {
            sprice = High[i + k];
            if (shi < sprice)
               shi = sprice;

            sprice = Low[i + k];
            if (slo > sprice)
               slo = sprice;
         }

         SpanA_Buffer[i] = (Kijun_Buffer[i] + Tenkan_Buffer[i]) * 0.5;
         SpanB_Buffer[i] = (shi + slo) * 0.5;

         //
         //
         //
         //
         //

         UpH[i] = EMPTY_VALUE;
         DnH[i] = EMPTY_VALUE;
         NuH[i] = EMPTY_VALUE;

         if (ShowNeutral)
            trend[i] = 0;
         else
            trend[i] = trend[i + 1];

         if (SpanA_Buffer[i] > SpanB_Buffer[i])
            trend[i] = 1;
         if (SpanA_Buffer[i] < SpanB_Buffer[i])
            trend[i] = -1;
         if (SpanA_Buffer[i] == SpanB_Buffer[i])
            trend[i] = 0;
         if (trend[i] == 1)
            UpH[i] = 1;
         if (trend[i] == -1)
            DnH[i] = 1;
         if (trend[i] == 0)
            NuH[i] = 1;
      }
      manageAlerts();
      return (0);
   }

   //
   //
   //
   //
   //

   limit = MathMax(limit, MathMin(Bars - 1, iCustom(NULL, timeFrame, indicatorFileName, "returnBars", 0, 0) * timeFrame / Period()));
   for (i = limit; i >= 0; i--)
   {
      int y = iBarShift(NULL, timeFrame, Time[i]);
      trend[i] = iCustom(NULL, timeFrame, indicatorFileName, "calculateValue", Tenkan, Kijun, Senkou, ShowNeutral, 7, y);
      UpH[i] = EMPTY_VALUE;
      DnH[i] = EMPTY_VALUE;
      NuH[i] = EMPTY_VALUE;

      if (trend[i] == 1)
         UpH[i] = 1;
      if (trend[i] == -1)
         DnH[i] = 1;
      if (trend[i] == 0)
         NuH[i] = 1;
   }
   manageAlerts();
   return (0);
}

//+-------------------------------------------------------------------
//|
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN"};
int iTfTable[] = {1, 5, 15, 30, 60, 240, 1440, 10080, 43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i = ArraySize(iTfTable) - 1; i >= 0; i--)
      if (tfs == sTfTable[i] || tfs == "" + iTfTable[i])
         return (MathMax(iTfTable[i], Period()));
   return (Period());
}

//
//
//
//
//

string timeFrameToString(int tf)
{
   for (int i = ArraySize(iTfTable) - 1; i >= 0; i--)
      if (tf == iTfTable[i])
         return (sTfTable[i]);
   return ("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string s = str;

   for (int length = StringLen(str) - 1; length >= 0; length--)
   {
      int tchar = StringGetChar(s, length);
      if ((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
         s = StringSetChar(s, length, tchar - 32);
      else if (tchar > -33 && tchar < 0)
         s = StringSetChar(s, length, tchar + 224);
   }
   return (s);
}

//+-------------------------------------------------------------------
//|
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
         int whichBar = 0;
      else
         whichBar = 1;
      whichBar = iBarShift(NULL, 0, iTime(NULL, timeFrame, whichBar));
      if (trend[whichBar] != trend[whichBar + 1])
      {
         if (trend[whichBar] == 1)
            doAlert(whichBar, "up");
         if (trend[whichBar] == -1)
            doAlert(whichBar, "down");
         if (trend[whichBar] == 0)
            doAlert(whichBar, "neutral");
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string previousAlert = "nothing";
   static datetime previousTime;
   string message;

   if (previousAlert != doWhat || previousTime != Time[forBar])
   {
      previousAlert = doWhat;
      previousTime = Time[forBar];

      //
      //
      //
      //
      //

      message = StringConcatenate(Symbol(), " at ", TimeToStr(TimeLocal(), TIME_SECONDS), " - ", timeFrameToString(timeFrame) + " SpanA - SpanB cross ", doWhat);
      if (alertsMessage)
         Alert(message);
      if (alertsEmail)
         SendMail(StringConcatenate(Symbol(), " SpanA - SpanB cross "), message);
      if (alertsSound)
         PlaySound("alert2.wav");
   }
}
