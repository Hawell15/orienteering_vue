<template>
    <Create ref="create" @save="saveCompetition" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Competiție</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveCompetition() {
    window.location = "/competitions?sorting[direction]=desc";
}
</script>
