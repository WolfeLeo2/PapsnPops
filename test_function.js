async function test() {
  const res = await fetch('https://ugxjqmqiatbsapjmajnw.supabase.co/functions/v1/notify-owner', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVneGpxbXFpYXRic2Fwam1ham53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDM3NDAsImV4cCI6MjA5NTgxOTc0MH0.6NXdrg-Pp3ZKyDVrubdgGWBiQLw4yYCpibE7QeBT3m8'
    },
    body: JSON.stringify({
      "type": "INSERT",
      "table": "sales",
      "record": { "total": 1700000 }
    })
  });
  console.log(res.status);
  console.log(await res.text());
}
test();
