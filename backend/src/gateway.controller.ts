import { All, Body, Controller, ForbiddenException, Param, Req, Res, UnauthorizedException } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { SupabaseService } from './supabase.service';
import { authEmailRedirect } from './auth-redirect';

const resources = new Map<string, Set<string>>([
  ['profiles',new Set(['GET','PATCH'])],['user_roles',new Set(['GET'])],
  ['host_applications',new Set(['GET'])],['host_profiles',new Set(['GET'])],
  ['experiences',new Set(['GET'])],['experience_images',new Set(['GET'])],
  ['bookings',new Set(['GET','POST'])],['reviews',new Set(['GET','POST'])],
  ['experience_likes',new Set(['GET','POST','DELETE'])],['experience_comments',new Set(['GET','POST','PATCH','DELETE'])],
  ['favorites',new Set(['GET','POST','DELETE'])],['host_follows',new Set(['GET','POST','DELETE'])],
  ['notifications',new Set(['GET','PATCH'])],['experience_feed',new Set(['GET'])],
  ['host_public_profiles',new Set(['GET'])],['review_feed',new Set(['GET'])],['my_bookings',new Set(['GET'])],
  ['countries',new Set(['GET'])],['regions',new Set(['GET'])],['cities',new Set(['GET'])],['currencies',new Set(['GET'])],['plan_categories',new Set(['GET'])],['profile_photos',new Set(['GET','POST','DELETE'])],
]);
const anonymous = new Set(['experience_feed','host_public_profiles','review_feed','experience_images','experience_comments','experience_likes','host_follows','host_profiles','experiences','reviews','countries','regions','cities','currencies','plan_categories']);
const authMethods: Record<string,string[]> = {signup:['POST'],token:['POST'],recover:['POST'],resend:['POST'],user:['GET','PUT'],logout:['POST'],verify:['POST']};
const hostActions = new Set(['submit_application','review_application','update_host_profile','save_experience','booking_status']);

export function allowedResource(resource:string,method:string){return resources.get(resource)?.has(method)??false;}

@Controller()
export class GatewayController {
  constructor(private readonly supabase:SupabaseService){}
  private async relay(path:string,req:Request,res:Response,body?:unknown) {
    const extra:Record<string,string>={};
    for(const key of ['prefer','range','range-unit','accept','accept-profile','content-profile']) {
      const value=req.header(key);
      if(value && !key.endsWith('profile'))extra[key]=value;
    }
    // All authorization comes from the verified user session and database RLS.
    const upstream=await this.supabase.request(path,req.method,req.header('authorization'),['GET','HEAD','DELETE'].includes(req.method)?undefined:body,extra);
    res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
    for(const key of ['content-type','content-range','range-unit']){const value=upstream.headers.get(key);if(value)res.setHeader(key,value);}
    // The Auth SDK needs provider error codes, but no credentials are logged.
    if(upstream.status>=500)return res.status(502).json({message:'Servicio temporalmente no disponible',code:'upstream_unavailable'});
    return res.status(upstream.status).send(await upstream.text());
  }
  @All('auth/v1/:action')
  @Throttle({default:{limit:12,ttl:60000}})
  async auth(@Param('action')action:string,@Req()req:Request,@Res()res:Response,@Body()body:Record<string,unknown>){
    if(!authMethods[action]?.includes(req.method))throw new ForbiddenException('Operación de cuenta no disponible');
    if(['signup','recover','resend'].includes(action) && req.method==='POST') {
      if(typeof body?.email!=='string'||!/^\S+@\S+\.\S+$/.test(body.email))return res.status(400).json({message:'Escribe un correo válido',code:'invalid_email'});
    }
    const query=new URLSearchParams(req.originalUrl.split('?')[1]||'');
    // Do not allow callers to redirect recovery links to unrelated websites.
    if(query.has('redirect_to') || ['signup','recover','resend'].includes(action) || (action==='user' && req.method==='PUT' && typeof body?.email==='string')) {
      query.set('redirect_to',authEmailRedirect(action,body));
    }
    return this.relay(`/auth/v1/${action}${query.size?'?'+query:''}`,req,res,body);
  }
  @All('rest/v1/:resource')
  async data(@Param('resource')resource:string,@Req()req:Request,@Res()res:Response,@Body()body:unknown){
    if(!allowedResource(resource,req.method))throw new ForbiddenException('Operación no disponible');
    const token=req.header('authorization');
    if(!(req.method==='GET'&&anonymous.has(resource)) && (!token?.startsWith('Bearer ')||token==='Bearer sb_publishable_mamba_frontend'))throw new UnauthorizedException('Inicia sesión');
    return this.relay(`/rest/v1/${resource}${req.originalUrl.includes('?')?'?'+req.originalUrl.split('?').slice(1).join('?'):''}`,req,res,body);
  }
  @All('rest/v1/rpc/:name')
  async rpc(@Param('name')name:string,@Req()req:Request,@Res()res:Response,@Body()body:{action?:string;payload?:unknown}){
    if(name!=='host_action'||req.method!=='POST'||!hostActions.has(body?.action??''))throw new ForbiddenException('Acción no disponible');
    await this.supabase.user(req.header('authorization'));
    return this.relay('/rest/v1/rpc/host_action',req,res,{action:body.action,payload:body.payload??{}});
  }
}
