<template>
  <form action="/parser/file_results" method="POST" enctype="multipart/form-data">
    <input
    type="hidden"
    name="authenticity_token"
    :value="csrfToken"
  />
    <input type="file" name="path" />

    <input type="checkbox" name="relay" value="1" id="relay" />
    <label for="relay">Stafeta?</label>

    <button type="submit" class="btn btn-primary">
      Încarcă
    </button>
  </form>
</template>

<script setup>
const csrfToken =
  document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
</script>
