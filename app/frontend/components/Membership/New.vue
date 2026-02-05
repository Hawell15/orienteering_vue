<template>
    <Create ref="create" @save="saveMemebership" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Afiliere</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveMemebership() {
    window.location = "/memberships?sorting[direction]=desc";
}
</script>
