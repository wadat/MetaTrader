//+------------------------------------------------------------------+
//|                                        Heiken_Ashi_Ma_Sign_1.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7

#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDeepSkyBlue,clrPaleVioletRed

#define MA_PERIOD 21
#define SIGNAL_SHIFT 0.5

input color COLOR_FAST = clrNONE; // 色
input color COLOR_SLOW = clrNONE; // 色

input int MA_WIDTH = 1; // 太さ

input ENUM_MA_METHOD MA_METHOD = MODE_SMA; // MA種別
input ENUM_APPLIED_PRICE APPLIED_PRICE = PRICE_CLOSE; // 適用価格
input ENUM_LINE_STYLE MA_STYLE = STYLE_SOLID; // 線種

//--- indicator buffers
double ExtOpenBuffer[], ExtHighBuffer[], ExtLowBuffer[], ExtCloseBuffer[];
double ExtColorBuffer[];
double BuySignal[], SellSignal[];

int handle; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(3, ExtCloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4, ExtColorBuffer,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, COLOR_FAST);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, COLOR_SLOW);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, MA_STYLE);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, MA_STYLE);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, MA_WIDTH);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, MA_WIDTH);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   ArraySetAsSeries(ExtOpenBuffer, true);
   ArraySetAsSeries(ExtHighBuffer, true);
   ArraySetAsSeries(ExtLowBuffer, true);
   ArraySetAsSeries(ExtCloseBuffer, true);

   //---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,MA_PERIOD-1);
   IndicatorSetString(INDICATOR_SHORTNAME,"Heiken Ashi Ma Candle");
   //--- sets drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

   // handle0 = iMA(NULL, 0, PERIOD_FAST, MA_SHIFT, MA_METHOD, APPLIED_PRICE);
   // handle1 = iMA(NULL, 0, PERIOD_SLOW, MA_SHIFT, MA_METHOD, APPLIED_PRICE);
   
   handle = iCustom(NULL,0,"Heiken_Ashi_Ma_Candle");

   SetIndexBuffer(6, BuySignal,INDICATOR_DATA);
   SetIndexBuffer(5, SellSignal,INDICATOR_DATA);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, clrDeepSkyBlue);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, clrPaleVioletRed);
   PlotIndexSetInteger(6, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(6, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(6, PLOT_ARROW, 233);
   PlotIndexSetInteger(5, PLOT_ARROW, 234);
   PlotIndexSetInteger(6, PLOT_ARROW_SHIFT, 10);
   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetString(6, PLOT_LABEL, "Buy");
   PlotIndexSetString(5, PLOT_LABEL, "Sell");
   ArraySetAsSeries(BuySignal, true);
   ArraySetAsSeries(SellSignal, true);
   //---
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   //---
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   int limit = rates_total - prev_calculated;
   if (limit < 1) limit = 1;

   int to_copy;
   to_copy = rates_total - prev_calculated;
   if(to_copy==0)
      to_copy++;

   CopyBuffer(handle, 0, 0, to_copy, ExtOpenBuffer);
   CopyBuffer(handle, 1, 0, to_copy, ExtHighBuffer);
   CopyBuffer(handle, 2, 0, to_copy, ExtLowBuffer);
   CopyBuffer(handle, 3, 0, to_copy, ExtCloseBuffer);
   
   //--- preliminary calculations
   int start;
   if(prev_calculated==0)
      start=1;
   else
      start=prev_calculated-1;

   //--- the main loop of calculations
   // for(int i=start; i<rates_total && !IsStopped(); i++) {
   
   if(prev_calculated==0) limit -= 2;
   
   for(int i=limit-1; i>=0; i--) {
      
      // BUY SIGNAL
      if(
         (
            ExtOpenBuffer[i+2] < ExtCloseBuffer[i+2] &&
            ExtOpenBuffer[i+1] < ExtCloseBuffer[i+1] &&
            ExtOpenBuffer[i] < ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] < open[i] &&
            ExtOpenBuffer[i] < close[i] &&
            ExtOpenBuffer[i] > low[i] &&
            open[i] < close[i] &&
            MathAbs(low[i]-open[i]) > MathAbs(close[i]-high[i])
         )
         /*   ||
         (
            ExtOpenBuffer[i] < ExtCloseBuffer[i] &&
            open[i+1] > close[i+1] &&
            //open[i] < close[i] &&
            (high[i] - low[i]) / 5 > MathAbs(open[i] - close[i]) &&
            MathAbs(low[i]-open[i]) > MathAbs(open[i]-high[i])
         )
            ||
         (
            ExtOpenBuffer[i+2] > ExtCloseBuffer[i+2] &&
            ExtOpenBuffer[i+1] > ExtCloseBuffer[i+1] &&
            ExtOpenBuffer[i] <= ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] < open[i] &&
            ExtOpenBuffer[i] < close[i] &&
            open[i] < close[i] &&
            MathAbs(low[i]-open[i]) > MathAbs(open[i]-high[i])
         )
            ||
         (
            ExtOpenBuffer[i] >= ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] < open[i] &&
            ExtOpenBuffer[i] < close[i]
         )*/
      )
         BuySignal[i] = ExtOpenBuffer[i] - SIGNAL_SHIFT;
      else 
         BuySignal[i] = EMPTY_VALUE;
      
      // SELL SIGNAL
      if(
         (
            ExtOpenBuffer[i+2] > ExtCloseBuffer[i+2] &&
            ExtOpenBuffer[i+1] > ExtCloseBuffer[i+1] &&
            ExtOpenBuffer[i] > ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] > open[i] &&
            ExtOpenBuffer[i] > close[i] &&
            ExtOpenBuffer[i] < high[i] &&
            open[i] > close[i] &&
            MathAbs(high[i]-open[i]) > MathAbs(close[i]-low[i])
         )
         /*   ||
         (
            ExtOpenBuffer[i] > ExtCloseBuffer[i] &&
            open[i+1] < close[i+1] &&
            //open[i] > close[i] &&
            (high[i] - low[i]) / 5 > MathAbs(open[i] - close[i]) &&
            MathAbs(high[i]-open[i]) > MathAbs(open[i]-low[i])
         )
            ||
         (
            ExtOpenBuffer[i+2] < ExtCloseBuffer[i+2] &&
            ExtOpenBuffer[i+1] < ExtCloseBuffer[i+1] &&
            ExtOpenBuffer[i] >= ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] > open[i] &&
            ExtOpenBuffer[i] > close[i] &&
            open[i] > close[i] &&
            MathAbs(high[i]-open[i]) > MathAbs(open[i]-low[i])
         )
            ||
         (
            ExtOpenBuffer[i] <= ExtCloseBuffer[i] &&
            ExtOpenBuffer[i] > open[i] &&
            ExtOpenBuffer[i] > close[i]
         )*/
      )
         SellSignal[i] = ExtOpenBuffer[i] + SIGNAL_SHIFT;
      else 
         SellSignal[i] = EMPTY_VALUE;
   }
   
   //--- return value of prev_calculated for next call
   return(rates_total);
}
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handle);
}
//+------------------------------------------------------------------+
