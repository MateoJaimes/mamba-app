import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { GatewayController } from './gateway.controller';
import { SupabaseService } from './supabase.service';
import { MailService } from './mail.service';
import { MediaController } from './media.controller';
import { CurrencyController } from './currency.controller';

@Module({
  imports: [ConfigModule.forRoot({isGlobal:true,envFilePath:['.env.local','.env']}),
    ThrottlerModule.forRoot([{ttl:60000,limit:120}])],
  controllers: [AppController,GatewayController,MediaController,CurrencyController],
  providers: [SupabaseService,MailService,{provide:APP_GUARD,useClass:ThrottlerGuard}],
})
export class AppModule {}
