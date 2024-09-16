// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/yp
//   TYPE  : module
// ================================  *
const {Entity} = require('@drumee/server-core');
const {Messenger, Cache} = require('@drumee/server-essentials');

class __callback extends Entity {
  async stripe() {
    console.log('-------------------------------Iamin--------------------------------------------------------------------------')
    const skey = Cache.getSysConf('stripe_skey');
    const stripe = require('stripe')(skey);
    const endpointSecret = Cache.getSysConf('stripe_endpointSecret') //   'whsec_FvGQGzUqzPP8rfdzDHjWER6xn4ehXXcN';
    console.log('----------Iamin--stripekey-----', Cache.getSysConf('stripe_skey'));
    console.log('----------Iamin---endpointSecret------', endpointSecret);
    const rawPayload = this.input.raw();
    let header = this.input.headers()
    const sig = header['stripe-signature'];
    let event;
    try {
      event = stripe.webhooks.constructEvent(rawPayload, sig, endpointSecret);

    } catch (err) {

      this.debug(`Webhook Error: ${err.message}`)
    }
    //await this.yp.await_proc('db_log_put', event.type);
    let session = event.data.object;
    let mydata = {}
    let mysession = {}
    console.log('-------------------------------TEST-EVENT.TYPE--------------------------------------------------------------------------', event.type)
    switch (event.type) {

      case 'invoice.paid': {

        if (session.status === 'paid') {

          let subscription = session.lines.data.filter(function (e) {
            return e.type == 'subscription';
          });

          let durstion = subscription[0].period
          subscription = subscription[0].metadata

          let entity_id = subscription.entity_id
          let plan = subscription.plan
          let period = subscription.period
          let recurring = subscription.recurring
          let start = durstion.start
          let end = durstion.end
          let price = subscription.price
          let offer_price = subscription.offer_price || 0
          let amount_paid = session.amount_paid
          let invoice_pdf = session.invoice_pdf
          let hosted_invoice_url = session.hosted_invoice_url
          let invoice_number = session.number
          let payment_intent_id = session.payment_intent
          let subscription_id = session.subscription


          await this.yp.await_proc('renewal_update', 'paid', entity_id, invoice_number, payment_intent_id, subscription_id,
            plan, period, recurring, start, end, price, offer_price,
            amount_paid, invoice_pdf, hosted_invoice_url, '{}');


          const quota = Cache.getSysConf(`${plan}_quota`)
          this.yp.await_proc('drumate_update_profile', entity_id, JSON.stringify({ quota: quota }))


          let notification = {
            entity_id, invoice_number, payment_intent_id, subscription_id,
            plan, period, recurring, start, end, price, offer_price, status: 'paid'
          }

          let recipients = await this.yp.await_proc('user_sockets', entity_id);
          let service = "subscription.paid";
          await RedisStore.sendData(this.payload(notification, { service }), recipients);

          // this.pushLiveUpdate({
          //   service: "subscription.paid",
          //   dest: {
          //     type: _a.drumate,
          //     hub_id: entity_id,
          //     area: _a.personal
          //   },
          //   model: notification,
          //   keys: '*'
          // });

          let vhost = await this.yp.await_proc('domain_exists', 1);
          let drumate = await this.yp.await_proc('drumate_get', entity_id);
          const subject = Cache.message('_renewal_succeed_subject', drumate.lang);
          const link = `${this.input.homepath(vhost.name)}#`;
          const msg = new Messenger({
            template: "butler/payment-success",
            subject,
            recipient: drumate.email,
            lex: Cache.lex(drumate.lang),
            data: {
              sender: drumate.fullname,
              recipient: drumate.email,
              redirect_link: link
            },
            handler: this.exception.email
          });
          await msg.send();

        }
        break;
      }



      case 'invoice.payment_failed': {

        if (session.status === 'open') {

          let subscription = session.lines.data.filter(function (e) {
            return e.type == 'subscription';
          });

          let durstion = subscription[0].period
          subscription = subscription[0].metadata

          let entity_id = subscription.entity_id
          let plan = subscription.plan
          let period = subscription.period
          let recurring = subscription.recurring
          let start = durstion.start
          let end = durstion.end
          let price = subscription.price
          let offer_price = subscription.offer_price || 0
          let amount_paid = session.amount_paid
          let invoice_pdf = session.invoice_pdf
          let hosted_invoice_url = session.hosted_invoice_url
          let invoice_number = session.number
          let payment_intent_id = session.payment_intent
          let subscription_id = session.subscription


          await this.yp.await_proc('renewal_update', 'open', entity_id, invoice_number, payment_intent_id, subscription_id,
            plan, period, recurring, start, end, price, offer_price,
            amount_paid, invoice_pdf, hosted_invoice_url, '{}');

          let notification = {
            entity_id, invoice_number, payment_intent_id, subscription_id,
            plan, period, recurring, start, end, price, offer_price, status: 'failed'
          }


          let mysubscription = await stripe.subscriptions.retrieve(subscription_id);


          if (mysubscription.status == 'incomplete') {

            await this.yp.await_proc('subscription_remove', entity_id, subscription_id)
            await this.yp.await_proc('renewal_failed_remove', entity_id, subscription_id)
            await this.yp.await_proc('renewal_history_failed_remove', entity_id, subscription_id)
          }
          else {


            let drumate = await this.yp.await_proc('drumate_get', entity_id);
            const subject = Cache.message('_renewal_failed_subject', drumate.lang);


            const msg = new Messenger({
              template: "butler/payment-fail",
              subject,
              recipient: drumate.email,
              lex: Cache.lex(drumate.lang),
              data: {
                sender: drumate.fullname,
                recipient: drumate.email,
                redirect_link: hosted_invoice_url
              },
              handler: this.exception.email
            });
            await msg.send();
            let recipients = await this.yp.await_proc('user_sockets', entity_id);
            let service = "subscription.failed";
            await RedisStore.sendData(this.payload(notification, { service }), recipients);
            // this.pushLiveUpdate({
            //   service: "subscription.failed",
            //   dest: {
            //     type: _a.drumate,
            //     hub_id: entity_id,
            //     area: _a.personal
            //   },
            //   model: notification,
            //   keys: '*'
            // });


          }

        }
        break;
      }

      case 'customer.subscription.created': {

        let subscription_id = session.id
        let customer_id = session.customer
        let status = session.status
        let plan = session.metadata.plan
        let period = session.metadata.period
        let recurring = session.metadata.recurring
        let price = session.metadata.price
        let offer_price = session.metadata.offer_price || 0
        let entity_id = session.metadata.entity_id

        await this.yp.await_proc('subscription_update', entity_id, customer_id, subscription_id, plan, period, recurring, price, offer_price, status)

        break;
      }



      case 'customer.subscription.updated': {

        let subscription_id = session.id
        let customer_id = session.customer
        let status = session.status
        let plan = session.metadata.plan
        let period = session.metadata.period
        let recurring = session.metadata.recurring
        let price = session.metadata.price
        let offer_price = session.metadata.offer_price || 0
        let entity_id = session.metadata.entity_id

        await this.yp.await_proc('subscription_update', entity_id, customer_id, subscription_id, plan, period, recurring, price, offer_price, status)

        if (status == 'incomplete_expired') {
          await this.yp.await_proc('subscription_remove', entity_id, subscription_id)
          await this.yp.await_proc('renewal_failed_remove', entity_id, subscription_id)
          await this.yp.await_proc('renewal_history_failed_remove', entity_id, subscription_id)

        }

        break;
      }


      case 'customer.subscription.deleted': {

        let subscription_id = session.id
        let entity_id = session.metadata.entity_id
        let invoice_id = session.latest_invoice
        await this.yp.await_proc('subscription_remove', entity_id, subscription_id)
        await this.yp.await_proc('renewal_failed_remove', entity_id, subscription_id)
        await this.yp.await_proc('renewal_history_failed_remove', entity_id, subscription_id)

        const quota = Cache.getSysConf('advanced_quota')
        await this.yp.await_proc('drumate_update_profile', entity_id, JSON.stringify({ quota: quota }))

        let notification = {
          entity_id, subscription_id,
          status: 'deleted'
        }

        let recipients = await this.yp.await_proc('user_sockets', entity_id);
        let service = "subscription.deleted";
        await RedisStore.sendData(this.payload(notification, { service }), recipients);

        // this.pushLiveUpdate({
        //   service: "subscription.deleted",
        //   dest: {
        //     type: _a.drumate,
        //     hub_id: entity_id,
        //     area: _a.personal
        //   },
        //   model: notification,
        //   keys: '*'
        // });


        const invoice = await stripe.invoices.retrieve(invoice_id);
        if (invoice.status == 'open') {
          await stripe.invoices.voidInvoice(invoice_id);
        }

        let vhost = await this.yp.await_proc('domain_exists', 1);
        let drumate = await this.yp.await_proc('drumate_get', entity_id);
        const subject = Cache.message('_subscription_expired_subject', drumate.lang);
        const link = `${this.input.homepath(vhost.name)}#/desk/account/subscription`;

        const msg = new Messenger({
          template: "butler/subscription-expired",
          subject,
          recipient: drumate.email,
          lex: Cache.lex(drumate.lang),
          data: {
            sender: drumate.fullname,
            recipient: drumate.email,
            redirect_link: link
          },
          handler: this.exception.email
        });
        await msg.send();

        break;
      }

    }
    this.output.data(mysession)
  }



  async check_out_cancel() {

    this.output.html(`<script>  window.location.href = '${this.input.homepath()}#/desk/?payment=false&cancel=true' </script>`)

  }




  async check_out_success() {

    const skey = Cache.getSysConf('stripe_skey');
    const stripe = require('stripe')(skey);
    const session_id = this.input.get('session_id');

    const session = await stripe.checkout.sessions.retrieve(session_id);

    this.output.html(`<script>  window.location.href = '${this.input.homepath()}#/desk/?payment=true&success=true&subscription_id=${session.subscription}' </script>`)

  }
}


module.exports = __callback;


