//+------------------------------------------------------------------+
//|                                            Heiken_Ashi_Ma_EA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade trade;
int barsTotal;
int handle_HM;
int handle_DC;
int handle_BB1;
int handle_BB2;

static int signal;

input double Lots = 0.01;
input int TpPoints = 1000;
input int SlPoints = 500;
input int TsPoints = 100;
input int TsTriggerPoints = 200;
input int MagicNumber = 1;

#define MA_PERIOD 20
#define DC_PERIOD 20

int OnInit() {

   trade.SetExpertMagicNumber(MagicNumber);
   handle_HM = iCustom(NULL,PERIOD_CURRENT,"Heiken_Ashi_Ma_Candle");
   handle_DC = iCustom(NULL,PERIOD_CURRENT,"Free Indicators//Donchian_Channel.ex5",DC_PERIOD,false);
   handle_BB1 = iBands(NULL,PERIOD_CURRENT,MA_PERIOD,0,1.0,PRICE_CLOSE);
   handle_BB2 = iBands(NULL,PERIOD_CURRENT,MA_PERIOD,0,2.0,PRICE_CLOSE);
   barsTotal = Bars(NULL,PERIOD_CURRENT);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {

   //--- indicator buffers
   double ExtOpenBuffer[], ExtHighBuffer[], ExtLowBuffer[], ExtCloseBuffer[];
   CopyBuffer(handle_HM, 0, 1, 3, ExtOpenBuffer);
   CopyBuffer(handle_HM, 1, 1, 3, ExtHighBuffer);
   CopyBuffer(handle_HM, 2, 1, 3, ExtLowBuffer);
   CopyBuffer(handle_HM, 3, 1, 3, ExtCloseBuffer);
   
   double UpperDonchain[], MiddleDonchain[], LowerDonchain[];
   CopyBuffer(handle_DC,0,0,1,UpperDonchain);
   CopyBuffer(handle_DC,1,0,1,MiddleDonchain);
   CopyBuffer(handle_DC,2,0,1,LowerDonchain);
   
   double UpperBand1[], MiddleBand1[], LowerBand1[];
   CopyBuffer(handle_BB1, 1, 0, 3, UpperBand1);
   CopyBuffer(handle_BB1, 0, 0, 3, MiddleBand1);
   CopyBuffer(handle_BB1, 2, 0, 3, LowerBand1);

   double UpperBand2[], MiddleBand2[], LowerBand2[];
   CopyBuffer(handle_BB2, 1, 0, 3, UpperBand2);
   CopyBuffer(handle_BB2, 0, 0, 3, MiddleBand2);
   CopyBuffer(handle_BB2, 2, 0, 3, LowerBand2);
      
   double open = iOpen(NULL,PERIOD_CURRENT,1);
   double high = iHigh(NULL,PERIOD_CURRENT,1);
   double low = iLow(NULL,PERIOD_CURRENT,1);
   double close = iClose(NULL,PERIOD_CURRENT,1);

   double open1 = iOpen(NULL,PERIOD_CURRENT,2);
   double high1 = iHigh(NULL,PERIOD_CURRENT,2);
   double low1 = iLow(NULL,PERIOD_CURRENT,2);
   double close1 = iClose(NULL,PERIOD_CURRENT,2);

   //--- Trailing stop
   if(TsTriggerPoints >= TsPoints && TsPoints > 0) { 
      for(int i=0; i<PositionsTotal(); i++) {
         ulong posTicket = PositionGetTicket(i);
         
         if(PositionGetSymbol(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         
         double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double posSl = PositionGetDouble(POSITION_SL);
         double posTp = PositionGetDouble(POSITION_TP);
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(bid > posPriceOpen+TsTriggerPoints*_Point) {
               double sl = posPriceOpen+TsPoints*_Point;
               sl = NormalizeDouble(sl,_Digits);
               if(sl > posSl || posSl == 0) trade.PositionModify(posTicket,sl,posTp);
            }
            if(ExtOpenBuffer[1] > posPriceOpen+TsTriggerPoints*_Point && posSl < ExtOpenBuffer[1]) {
               double sl = NormalizeDouble(ExtOpenBuffer[1],_Digits);
               if(sl > posSl || posSl == 0) trade.PositionModify(posTicket,sl,posTp);
            }
         } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(ask < posPriceOpen-TsTriggerPoints*_Point) {
               double sl = posPriceOpen-TsPoints*_Point;
               sl = NormalizeDouble(sl,_Digits);
               if(sl < posSl || posSl == 0) trade.PositionModify(posTicket,sl,posTp);
            }
            if(ExtOpenBuffer[1] < posPriceOpen-TsTriggerPoints*_Point && posSl > ExtOpenBuffer[1]) {
               double sl = NormalizeDouble(ExtOpenBuffer[1],_Digits);
               if(sl < posSl || posSl == 0) trade.PositionModify(posTicket,sl,posTp);
            }
         }
      }
   }

   int bars = iBars(NULL,PERIOD_CURRENT);
   if(barsTotal != bars)
   {
      barsTotal = bars;

      /*
      //--- Close positions
      for(int i=0; i<PositionsTotal(); i++) {
         ulong posTicket = PositionGetTicket(i);
         
         if(PositionGetSymbol(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
            ExtOpenBuffer[1] > ExtCloseBuffer[1] && 
            ExtOpenBuffer[2] < ExtCloseBuffer[2]
         ) {
            if(trade.PositionClose(posTicket)) {
               Print("Position #",posTicket," was closed");
            }
         } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
                   ExtOpenBuffer[1] < ExtCloseBuffer[1] && 
                   ExtOpenBuffer[2] > ExtCloseBuffer[2]
         ) {
            if(trade.PositionClose(posTicket)) {
               Print("Position #",posTicket," was closed");
            }
         }
      }
      */

      /*
      // Open additional positions
      if(signal == 1) {
         if(ExtOpenBuffer[1] > ExtCloseBuffer[1] && ExtOpenBuffer[2] < ExtCloseBuffer[2]) {
            Print("Additional Buy Signal");
            signal = 1;
            exeBuy();
         }
      } else if(signal == -1) {
         if(ExtOpenBuffer[1] < ExtCloseBuffer[1] && ExtOpenBuffer[2] > ExtCloseBuffer[2]) {
            Print("Additional Sell Signal");
            signal = -1;
            exeSell();
         }
      }
      */
      
      // Open positions
      if(
         (
            ExtOpenBuffer[0] < ExtCloseBuffer[0] && 
            ExtOpenBuffer[1] < ExtCloseBuffer[1] &&
            ExtOpenBuffer[2] < ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] < open && 
            ExtOpenBuffer[2] < close && 
            ExtOpenBuffer[2] > low &&
            open < close &&
            MathAbs(low-open) > MathAbs(close-high)
         )
            ||
         (
            ExtOpenBuffer[2] < ExtCloseBuffer[2] &&
            open1 > close1 &&
            // open < close &&
            (high-low) / 5 > MathAbs(open-close) &&
            MathAbs(low-open) > MathAbs(close-high)
         )
         /*
            ||
         (
            ExtOpenBuffer[0] > ExtCloseBuffer[0] &&
            ExtOpenBuffer[1] > ExtCloseBuffer[1] &&
            ExtOpenBuffer[2] <= ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] < open &&
            ExtOpenBuffer[2] < close &&
            open < close
            //MathAbs(low[i]-open[i]) > MathAbs(open[i]-high[i])
         )
            ||
         (
            ExtOpenBuffer[2] >= ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] < open &&
            ExtOpenBuffer[2] < close
         )
         */
      ) {
         Print("Buy Signal");
         signal = 1;
         closePositions(POSITION_TYPE_SELL);
         openBuy();
      }
      
      if(
         (
            ExtOpenBuffer[0] > ExtCloseBuffer[0] && 
            ExtOpenBuffer[1] > ExtCloseBuffer[1] &&
            ExtOpenBuffer[2] > ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] > open &&
            ExtOpenBuffer[2] > close && 
            ExtOpenBuffer[2] < high &&
            open > close &&
            MathAbs(high-open) > MathAbs(close-low)         
         )
            ||
         (
            ExtOpenBuffer[2] > ExtCloseBuffer[2] &&
            open1 < close1 &&
            // open > close &&
            (high - low) / 5 > MathAbs(open - close) &&
            MathAbs(high-open) > MathAbs(close-low)
         )
         /*
            ||
         (
            ExtOpenBuffer[0] < ExtCloseBuffer[0] &&
            ExtOpenBuffer[1] < ExtCloseBuffer[1] &&
            ExtOpenBuffer[2] >= ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] > open &&
            ExtOpenBuffer[2] > close &&
            open > close
            //MathAbs(high[i]-open[i]) > MathAbs(open[i]-low[i])
         )
            ||
         (
            ExtOpenBuffer[2] <= ExtCloseBuffer[2] &&
            ExtOpenBuffer[2] > open &&
            ExtOpenBuffer[2] > close
         )
         */
      ) {
         Print("Sell Signal");
         signal = -1;
         closePositions(POSITION_TYPE_BUY);
         openSell();
      }
   }
   
   Comment(
      "Signal: ",signal,
      "\nLots: ",Lots,
      "\nTP: ",TpPoints,
      "\nSL: ",SlPoints,
      "\nTS: ",TsPoints,
      "\nBE: ",TsTriggerPoints,
      "\n",
      "\n+2s: ",NormalizeDouble(UpperBand2[0], _Digits),
      "\n+1s: ",NormalizeDouble(UpperBand1[0], _Digits),
      "\nMA: ", NormalizeDouble(MiddleBand1[0],_Digits),
      "\n-1s: ",NormalizeDouble(LowerBand1[0], _Digits),
      "\n-2s: ",NormalizeDouble(LowerBand2[0], _Digits),
      "\n",
      "\nUpper: ",NormalizeDouble(UpperDonchain[0], _Digits),
      "\nMiddlw: ", NormalizeDouble(MiddleDonchain[0],_Digits),
      "\nLower: ",NormalizeDouble(LowerDonchain[0], _Digits)    
   );
}

void openBuy()
{
   double entry = SymbolInfoDouble(NULL,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);
   
   double tp = 0;
   if(TpPoints > 0) {
      tp = entry + TpPoints*_Point;
      tp = NormalizeDouble(tp,_Digits);
   }

   double sl = 0;
   if(SlPoints > 0) {
      sl = entry - SlPoints*_Point;
      sl = NormalizeDouble(sl,_Digits);
   }
   
   trade.Buy(Lots,NULL,entry,sl,tp);
}

void openSell()
{
   double entry = SymbolInfoDouble(NULL,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   
   double tp = 0;
   if(TpPoints > 0) {
      tp = entry - TpPoints*_Point;
      tp = NormalizeDouble(tp,_Digits);  
   }
   
   double sl = 0;
   if(SlPoints > 0) {
      sl = entry + SlPoints*_Point;
      sl = NormalizeDouble(sl,_Digits);
   }
   
   trade.Sell(Lots,NULL,entry,sl,tp);
}

void closePositions(ENUM_POSITION_TYPE pos_type)
{
   //--- Close positions
   for(int i=0; i<PositionsTotal(); i++) {
      ulong posTicket = PositionGetTicket(i);
      
      if(PositionGetSymbol(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      if(PositionGetInteger(POSITION_TYPE) == pos_type
      ) {
         if(trade.PositionClose(posTicket)) {
            Print("Buy Position #",posTicket," was closed");
         }
      } else if(PositionGetInteger(POSITION_TYPE) == pos_type
      ) {
         if(trade.PositionClose(posTicket)) {
            Print("Sell Position #",posTicket," was closed");
         }
      }
   }
}
