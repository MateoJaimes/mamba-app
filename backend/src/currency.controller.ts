import { BadRequestException, Controller, Get, Query, ServiceUnavailableException } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const supported=new Set(['COP','USD','EUR','GBP','MXN','BRL','CAD','AUD','JPY','CHF','CNY','PEN','CLP','ARS']);
@Controller('api/currency')
export class CurrencyController {
  private rates:Record<string,number>={COP:1};
  private updatedAt='';
  private validUntil=0;
  private requestInFlight?:Promise<void>;
  constructor(){
    try{const cached=JSON.parse(readFileSync(join(process.cwd(),'data/fx-source.json'),'utf8'));this.use(cached);}catch{/* Network refresh is used when no snapshot is bundled. */}
  }
  private use(data:any){
    if(data.result!=='success'||data.base_code!=='COP'||data.rates?.COP!==1)throw new Error('invalid rates');
    this.rates=data.rates;this.updatedAt=new Date(data.time_last_update_unix*1000).toISOString();this.validUntil=data.time_next_update_unix*1000;
  }
  private async refresh(){
    const r=await fetch('https://open.er-api.com/v6/latest/COP',{signal:AbortSignal.timeout(8000)});
    if(!r.ok)throw new Error('rates unavailable');this.use(await r.json());
  }
  @Get()
  async quote(@Query('code')code='COP'){
    if(!supported.has(code))throw new BadRequestException('Divisa no disponible');
    if(code==='COP')return {code,rate:1,base:'COP',updatedAt:new Date().toISOString(),approximate:false};
    if(Date.now()>this.validUntil){
      this.requestInFlight??=this.refresh().finally(()=>{this.requestInFlight=undefined;});
      try{await this.requestInFlight;}catch{/* Retain the last verified snapshot and expose its age. */}
    }
    if(!this.rates[code]||!this.updatedAt||Date.now()-Date.parse(this.updatedAt)>7*86400000)throw new ServiceUnavailableException('No hay una tasa reciente disponible. Conserva COP e inténtalo después.');
    return {code,rate:this.rates[code],base:'COP',updatedAt:this.updatedAt,approximate:true,provider:'https://www.exchangerate-api.com',stale:Date.now()>this.validUntil};
  }
}
